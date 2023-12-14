variable "ODD_SPINE_VERSION" {
  description = "Inherits the software version to run on Cisco ACI Odd Numbered Spine Nodes"
  type        = string
  default     = "simsw-6.0(2h)"
}

variable "EVEN_SPINE_VERSION" {
  description = "Inherits the software version to run on Cisco ACI Even Numbered Spine Nodes"
  type        = string
  default     = "simsw-6.0(2h)"
}

variable "ODD_LEAF_VERSION" {
  description = "Inherits the software version to run on Cisco ACI Odd Numbered Leaf Nodes"
  type        = string
  default     = "simsw-6.0(2h)"
}

variable "EVEN_LEAF_VERSION" {
  description = "Inherits the software version to run on Cisco ACI Even Numbered Leaf Nodes"
  type        = string
  default     = "simsw-6.0(2h)"
}