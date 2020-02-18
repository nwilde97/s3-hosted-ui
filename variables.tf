variable tags {
  type = map(string)
}

variable subdomain {
  description = "The subdomain to be used in the URL, prepended to 'zone_name'"
  type = string
}

variable zone_name {
  type = string
}

variable cert_domain {
  description = "The domain of the cert to be used for the API"
  type = string
}

variable bucket {
  description = "Bucket where UI assets are stored"
  type = string
}

variable prefix {
  description = "Prefix assigned to S3 resources, base path of app relative to this folder"
  type = string
}

variable stage_name {
  description = "Name of the stage to deploy, defaults to preprod. Not required"
  type = string
  default = "preprod"
}
