
locals {
  cluster_domain_name = "some-domain"

  # You can provision the subdomains directly
  cluster_a_records_subdomains = [
    "*.some-domain",
  ]

  sg_nlb_zone_id = ""
  sg_nlb_dns_name = ""
}
