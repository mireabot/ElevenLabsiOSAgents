![Banner](https://github.com/mireabot/ElevenLabsiOSAgents/blob/main/AI%20voice%20agents%20cover.png)
# AI Voice agents in iOS apps
With new wave of agentic AI and voice capabilities you can enhance app experience by delegating data manipulation and UI generation to user's voice (maybe it's agentic UI for mobile apps...) - this upgrade gives kind of `wow` effect
## Features
- Voice agents powered by [ElevenLabs](https://elevenlabs.io/)
- Structured data retrivial from voice input and UI generation
- External data browsing and generating insights + UI
## Get started
1. Clone or download this repository
2. Create an account and agents via ElevenLabs [dashboard](https://elevenlabs.io/app/agents)
3. Use [agents.md](https://github.com/mireabot/ElevenLabsiOSAgents/blob/main/agents.md) file to copy agents and tools from demo project
## Core files
- `Agent.swift` - create new agents with agent_id from dashboard
- `ConversationService.swift` - main service handling everything about conversation - selecting agent, creating a room, handling client tools
- `ToolResult.swift` - protocol and exmaples of data objects which will populate tool result

---
[Demo video](https://youtu.be/xEtDY_ip300) | [Fluid gradient package](https://github.com/Cindori/FluidGradient)
