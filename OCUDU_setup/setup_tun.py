#!/usr/bin/env python3

import ipaddress

import click
import iptc
from pyroute2 import IPRoute
from pyroute2.netlink import NetlinkError


def parse_network(ctx, param, value):
    try:
        return ipaddress.ip_network(value)
    except ValueError as error:
        raise click.BadParameter(f"{value} is not a valid IP range") from error


def add_firewall_rules(if_name, network):
    nat_chain = iptc.Chain(iptc.Table(iptc.Table.NAT), "POSTROUTING")
    nat_rule = iptc.Rule()
    nat_rule.src = network.with_prefixlen
    nat_rule.out_interface = f"!{if_name}"
    nat_rule.target = iptc.Target(nat_rule, "MASQUERADE")
    nat_chain.insert_rule(nat_rule)

    input_chain = iptc.Chain(iptc.Table(iptc.Table.FILTER), "INPUT")

    icmp_rule = iptc.Rule()
    icmp_rule.in_interface = if_name
    icmp_rule.protocol = "icmp"
    icmp_rule.create_match("icmp").icmp_type = "echo-request"
    icmp_rule.target = iptc.Target(icmp_rule, "ACCEPT")
    input_chain.append_rule(icmp_rule)

    for protocol in ("tcp", "udp"):
        iperf_rule = iptc.Rule()
        iperf_rule.in_interface = if_name
        iperf_rule.protocol = protocol
        iperf_rule.create_match(protocol).dport = "5201"
        iperf_rule.target = iptc.Target(iperf_rule, "ACCEPT")
        input_chain.append_rule(iperf_rule)

    reject_rule = iptc.Rule()
    reject_rule.in_interface = if_name
    reject_rule.target = iptc.Target(reject_rule, "REJECT")
    input_chain.append_rule(reject_rule)


@click.command()
@click.option("--if_name", default="ogstun", help="TUN interface name.")
@click.option(
    "--ip_range",
    default="10.45.0.0/24",
    callback=parse_network,
    help="First /24 in the UE address range.",
)
def main(if_name, ip_range):
    network = ip_range.supernet(new_prefix=16) if ip_range.prefixlen > 16 else ip_range
    ipr = IPRoute()

    try:
        ipr.link("add", ifname=if_name, kind="tuntap", mode="tun")
    except NetlinkError as error:
        if error.code != 17:
            raise

    device = ipr.link_lookup(ifname=if_name)[0]
    for subnet in network.subnets(new_prefix=24):
        gateway = str(next(subnet.hosts()))
        try:
            ipr.addr("add", index=device, address=gateway, mask=24)
        except NetlinkError as error:
            if error.code != 17:
                raise

    ipr.link("set", index=device, state="up")
    add_firewall_rules(if_name, network)


if __name__ == "__main__":
    main()
