# Weekly South Bay Events Automation Plan

## Overview
Automated n8n workflow that searches for cool local events in the South Bay area (near Sunnyvale) every Thursday using Perplexity AI and sends results via Discord message.

## Workflow Architecture

### 1. Schedule Trigger
- **Node Type**: Schedule Trigger
- **Schedule**: Every Thursday at 9:00 AM PST
- **Cron Expression**: `0 9 * * 4` (9 AM every Thursday)

### 2. Perplexity AI Search
- **Node Type**: HTTP Request
- **Method**: POST
- **URL**: `https://api.perplexity.ai/chat/completions`
- **Headers**:
  - `Authorization: Bearer YOUR_PERPLEXITY_API_KEY`
  - `Content-Type: application/json`

### 3. Search Query Configuration
**Perplexity Search Prompt**:
```
Find cool and interesting events happening this weekend and next week in the South Bay area near Sunnyvale, California. Include:
- Tech meetups and conferences
- Art exhibitions and cultural events
- Food festivals and markets
- Music concerts and performances
- Outdoor activities and festivals
- Unique local experiences

Format the response as a structured list with event name, date, location, and brief description. Focus on events that would be interesting to a tech professional living in Sunnyvale.
```

### 4. Response Processing
- **Node Type**: Code (JavaScript)
- **Purpose**: Parse Perplexity response and format for Discord
- **Output**: Formatted event list with emojis and structure

### 5. Discord Notification
- **Node Type**: Discord (Webhook)
- **Webhook URL**: Discord channel webhook URL
- **Message Format**: Rich embed with event details

## Required Setup Steps

### Prerequisites
1. **Perplexity AI API Key**
   - Sign up at https://perplexity.ai
   - Generate API key from dashboard
   - Store in n8n credentials manager

2. **Discord Webhook**
   - Create Discord server/channel for notifications
   - Generate webhook URL from channel settings
   - Store webhook URL in n8n credentials

### n8n Configuration

#### Step 1: Create New Workflow
1. Open n8n interface (http://localhost:5678)
2. Create new workflow: "Weekly South Bay Events"
3. Add description: "Automated Perplexity search for local events with Discord notifications"

#### Step 2: Configure Schedule Trigger
```json
{
  "rule": {
    "interval": [
      {
        "field": "cronExpression",
        "cronExpression": "0 9 * * 4"
      }
    ]
  }
}
```

#### Step 3: Configure Perplexity HTTP Request
```json
{
  "method": "POST",
  "url": "https://api.perplexity.ai/chat/completions",
  "headers": {
    "Authorization": "Bearer {{$credentials.perplexityApi.apiKey}}",
    "Content-Type": "application/json"
  },
  "body": {
    "model": "llama-3.1-sonar-large-128k-online",
    "messages": [
      {
        "role": "user",
        "content": "Find cool and interesting events happening this weekend and next week in the South Bay area near Sunnyvale, California. Include tech meetups, art exhibitions, food festivals, music concerts, outdoor activities, and unique local experiences. Format as a structured list with event name, date, location, and brief description."
      }
    ],
    "temperature": 0.3,
    "max_tokens": 1000
  }
}
```

#### Step 4: Configure Response Processing Code
```javascript
// Parse Perplexity response and format for Discord
const response = items[0].json;
const events = response.choices[0].message.content;

// Format for Discord with emojis
const formattedMessage = `# 🎉 Cool Events This Week in South Bay! 

${events}

---
*Automated search powered by Perplexity AI*
*Location: South Bay Area (near Sunnyvale, CA)*`;

return [{
  json: {
    content: formattedMessage,
    embeds: [{
      title: "🗓️ Weekly South Bay Events",
      description: events,
      color: 3447003,
      timestamp: new Date().toISOString(),
      footer: {
        text: "Automated via n8n + Perplexity AI"
      }
    }]
  }
}];
```

#### Step 5: Configure Discord Webhook
```json
{
  "webhookUrl": "{{$credentials.discordWebhook.webhookUrl}}",
  "content": "{{$json.content}}",
  "embeds": "{{$json.embeds}}"
}
```

## Security Configuration

### API Key Management
1. **Perplexity API Key**:
   - Store in n8n Credentials: `perplexityApi`
   - Type: Header Auth
   - Header: `Authorization`
   - Value: `Bearer YOUR_API_KEY`

2. **Discord Webhook**:
   - Store in n8n Credentials: `discordWebhook`
   - Type: Generic Credential
   - Field: `webhookUrl`

### Environment Variables
Add to `.env` file:
```bash
# Do not commit actual keys - use dummy values
PERPLEXITY_API_KEY=dummy-key-for-development
DISCORD_WEBHOOK_URL=dummy-webhook-for-development
```

## Testing Strategy

### Manual Testing
1. **Test Perplexity API**:
   - Use Postman/curl to verify API response
   - Validate search results quality
   - Check rate limits and response time

2. **Test Discord Integration**:
   - Send test message to webhook
   - Verify formatting and embeds
   - Test error handling

3. **Test Full Workflow**:
   - Trigger manually in n8n
   - Verify end-to-end execution
   - Check logs for errors

### Monitoring
- Enable workflow execution logging
- Set up error notifications
- Monitor API usage and costs

## Deployment Checklist

- [ ] Perplexity AI account created and API key obtained
- [ ] Discord server/channel set up with webhook
- [ ] API credentials configured in n8n
- [ ] Workflow created and tested
- [ ] Schedule trigger configured for Thursdays 9 AM
- [ ] Error handling implemented
- [ ] Monitoring and logging enabled
- [ ] Documentation updated

## Maintenance

### Weekly Review
- Check workflow execution logs
- Review event quality and relevance
- Adjust search prompts if needed

### Monthly Review
- Monitor API usage and costs
- Update search criteria based on interests
- Review and optimize workflow performance

## Cost Considerations

### Perplexity AI
- Current pricing: ~$1 per 1000 tokens
- Estimated weekly cost: $0.10-0.50
- Monthly estimate: $2-8

### n8n
- Self-hosted (no additional cost)
- Consider execution limits if using n8n Cloud

## Future Enhancements

### Potential Improvements
1. **Smart Filtering**:
   - Learn from past event preferences
   - Filter by event type preferences
   - Remove duplicate or recurring events

2. **Rich Notifications**:
   - Add event images when available
   - Include direct booking/registration links
   - Add calendar integration (ICS files)

3. **Multi-Platform**:
   - Send to multiple Discord channels
   - Add Slack integration
   - Email digest option

4. **Location Customization**:
   - Allow dynamic location updates
   - Include weather information
   - Factor in traffic/commute times

### Advanced Features
- **Interactive Discord Bot**: Allow users to RSVP or save events
- **Collaborative Filtering**: Share events with friends/teams
- **Integration with Calendar Apps**: Auto-add interesting events
- **Event Recommendation Engine**: ML-based event suggestions

## Notes
- Events data quality depends on Perplexity's current web crawling
- Consider backup event sources (Eventbrite API, Meetup API)
- Test thoroughly before relying on automated notifications
- Adjust timing based on personal schedule preferences