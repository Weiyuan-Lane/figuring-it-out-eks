
resource "aws_route53_zone" "dns" {
  name = local.cluster_domain_name
}

resource "aws_route53_record" "dns_sg_cluster_records" {
  count = length(local.cluster_a_records_subdomains)

  zone_id = aws_route53_zone.dns.zone_id
  name    = local.cluster_a_records_subdomains[count.index]
  type    = "A"

  alias {
    name                   = local.sg_nlb_dns_name
    zone_id                = local.sg_nlb_zone_id
    evaluate_target_health = true
  }
}
