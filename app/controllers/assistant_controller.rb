class AssistantController < ApplicationController
  def show
    @question = params[:question].to_s.strip
    return if @question.blank?

    context = gather_context(@question)
    @response = ask_claude(@question, context)
  end

  private

  def gather_context(question)
    context_parts = []

    # All appliances (small dataset, include all)
    appliances = Appliance.all
    if appliances.any?
      context_parts << "## Appliances\n" + appliances.map { |a|
        details = [a.name]
        details << "Location: #{a.location}" if a.location.present?
        details << "Brand: #{a.brand}" if a.brand.present?
        details << "Model: #{a.model_number}" if a.model_number.present?
        details << "Notes: #{a.notes}" if a.notes.present?
        details.join(", ")
      }.join("\n")
    end

    # Relevant wiki pages (keyword search)
    keywords = question.downcase.split(/\s+/).reject { |w| w.length < 3 }
    wiki_pages = WikiPage.all.select do |page|
      keywords.any? do |keyword|
        page.title.downcase.include?(keyword) ||
        page.body.to_s.downcase.include?(keyword)
      end
    end.first(10)

    if wiki_pages.any?
      context_parts << "## Wiki Pages\n" + wiki_pages.map { |p|
        "### #{p.title}\n#{p.body}"
      }.join("\n\n")
    end

    # Upcoming reminders
    reminders = Reminder.pending.by_due_date.limit(10)
    if reminders.any?
      context_parts << "## Upcoming Reminders\n" + reminders.map { |r|
        "- #{r.title} (due: #{r.due_date.strftime('%B %d, %Y')})"
      }.join("\n")
    end

    context_parts.join("\n\n")
  end

  def ask_claude(question, context)
    api_key = Rails.application.credentials.dig(:anthropic, :api_key)
    return "API key not configured. Please add your Anthropic API key to Rails credentials." if api_key.blank?

    client = Anthropic::Client.new(api_key: api_key)

    system_prompt = <<~PROMPT
      You are a helpful home assistant for a household. You have access to information about
      the household's appliances, wiki documentation, and reminders.

      Answer questions helpfully and concisely. If you don't have enough information to answer,
      say so. Format your response using markdown.

      Here is the household information:

      #{context}
    PROMPT

    response = client.messages.create(
      model: "claude-sonnet-4-20250514",
      max_tokens: 1024,
      system: system_prompt,
      messages: [{ role: "user", content: question }]
    )

    response.content.first.text
  rescue Anthropic::Error => e
    "Sorry, I couldn't process your question. Error: #{e.message}"
  rescue StandardError => e
    Rails.logger.error("AI Assistant error: #{e.message}")
    "Sorry, something went wrong. Please try again."
  end
end
