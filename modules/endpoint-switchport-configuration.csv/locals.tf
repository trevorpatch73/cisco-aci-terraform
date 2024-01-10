locals {
  iterations = csvdecode(file("./data/endpoint-switchport-configuration.csv"))
  
}
