variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "instance_ids" {
  type = list(string)
}

variable "tags" {
  description = "Optional map of tags to set on resources, defaults to empty map."
  type        = map(string)
  default     = {}
}

variable "internal_port" {
  type = number
}

variable "public_port" {
  type = number
}

variable "load_balancer_arn" {
  type = string
}

#variable "target_routes" {
#  type = list(object({
#    internal_port = number
#    public_port   = number
#    protocol      = string
#  }))
#  validation {
#    condition     = contains(["HTTP", "HTTPS", "TCP"], var.target_routes.*.protocol)
#    error_message = "Protocol must be HTTP, HTTPS or TCP"
#  }