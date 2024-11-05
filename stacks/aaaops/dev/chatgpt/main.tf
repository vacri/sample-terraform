terraform {
  required_providers {
    chatgpt = {
      source = "develeap/chatgpt"
    }
  }
}

provider "chatgpt" {
  api_key = var.chatgpt_api_key
}

resource "chatgpt_prompt" "query" {
  query      = var.q
  max_tokens = var.chars
}

output "result" {
  value = chatgpt_prompt.query.result
}

variable "q" {
  type = string
}

variable "chatgpt_api_key" {
  type = string
}

variable "chars" {
  type    = string
  default = 1024
}
