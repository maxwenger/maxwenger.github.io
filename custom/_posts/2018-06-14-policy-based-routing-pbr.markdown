---
layout: post
title: "Policy-Based Routing (PBR)"
date: 2018-06-14
categories:
  - Networking
  - Routing
description:
image: /assets/img/2018-06-14-policy-based-routing-pbr/cover.png
image-sm: /assets/img/2018-06-14-policy-based-routing-pbr/cover-sm.png
---

# Policy-Based Routing (PBR)

Policy-Based routing gives network administrators very granular control over their networks. Administrators can control how the traffic flows by source and/or destination, protocol, size of the packet, or even time of day. PBR harness the power of access lists and route maps. PBR is a list of criteria that changes how the packet is routed if it matches the criteria before it is routed by the routing table.

## Background Information

At the point that a Cisco Certificate Candidate is exploring Policy-Based Routing, they have already encountered many different types of routing protocols. If asked to categorize routing protocols, the differences between RIP and OSPF can easily be differentiated by describing distance vector and link state protocols. But they are both dynamic protocols. Policy-Based Routing is a "routing protocol" just as much as static routes are a routing protocol.

A route map is a logic structure that allows very granular control of the flow of traffic. It uses `match` statements to define a condition, and `set` statements to modify the traffic if the condition is met. These `match` statements can be defined using an access list (standard or extended) using the `match ip address <ACL Name/Number>`.

If traffic "matches" the access lists, it continues to the `set` statements. The `set` statements change how the traffic is routed. It is the action preformed if the traffic matches the initial statement.

## Lab Summary

Our task is to write a network policy that only allows HTTP traffic to route to the HTTP-Responder and HTTPS traffic to go to the HTTPS-Responder. Although both HTTP and HTTPS will be enabled on both routers, only its respective traffic should be routed to it.

## Lab Topology

![Topology](/assets/img/2018-06-14-policy-based-routing-pbr/topology.png)
![Route Map Flow Chart](/assets/img/2018-06-14-policy-based-routing-pbr/flow.png)

## Configuration

1. Basic configuration including IP addresses.
2. Configure HTTP and HTTPS responders with HTTP servers with secure server and authentication enabled.
3. Create access lists for HTTP and HTTPS routes.
4. Create a Route-Map to route HTTP and HTTPS traffic using the previously created ACLs.
5. Apply the route maps to the interface.
6. Verify the configurations.

### Configure HTTP and HTTPS Responders

The configuration for both routers are the same except for a null route to prevent re-routing filtered traffic.

The following commands creates a user `admin`, enables the HTTP and HTTPS services, and uses local authentication to login to the service (previously created user `admin` can login to the server).

```cisco
username admin privilege 15 secret cisco
ip http server
ip http secure-server
ip http authentication local
```

The configurations that differ between the two responders is the null route. This route is a fix for the issue outlined in the problems section. It prevents filtered traffic from being re-routed to the other router.

#### HTTP-Responder

```cisco
ip route 10.2.2.2 255.255.255.255 null0
```

#### HTTPS-Responder

```cisco
ip route 10.1.1.2 255.255.255.255 null0
```

### HTTP and HTTPS Access Lists

These two access lists will `permit` all HTTP or HTTPS traffic respectively. Anything permitted by the access lists with fulfill the `match` condition in the route-maps.

```cisco
ip access-list extended HTTP_Route
  permit tcp any any eq 80
ip access-list extended HTTPS_Route
  permit tcp any any eq 443
```

### Web_Policy Route Map

The route map will include two sequences for HTTP and HTTPS traffic. One sequence will `match` against the HTTP route, and another will `match` against the HTTPS route. It will then forward the matching traffic out the correct interface towards the HTTP or HTTPS Responder respectively.

```cisco
route-map Web_Policy 10
  match ip address HTTP_Route
  set ip next-hop 10.1.1.2
  set interface serial 0/0/0
route-map Web_Policy 20
  match ip address HTTPS_Route
  set ip next-hop 10.2.2.2
  set interface serial 0/0/1
```

### Apply the Web_Policy to a Interface

We want the traffic to be filtered at the interface closest to the client. In this case, that's the `FastEthernet0/0` interface. This will only filter traffic on that interface, no other interfaces will be affected.

```cisco
interface FastEthernet0/0
  ip policy route-map Web_Policy
```

### Verification

```cisco
Core#show access-lists HTTP_Route
Extended IP access list HTTP_Route
    10 permit tcp any any eq www
Core#show access-lists HTTPS_Route
Extended IP access list HTTPS_Route
    10 permit tcp any any eq 443
```

```cisco
Core#show route-map Web_Policy
route-map Web_Policy, permit, sequence 10
  Match clauses:
    ip address (access-lists): HTTP_Route
  Set clauses:
    ip next-hop 10.1.1.2
    interface Serial0/0/0
  Policy routing matches: 0 packets, 0 bytes
route-map Web_Policy, permit, sequence 20
  Match clauses:
    ip address (access-lists): HTTPS_Route
  Set clauses:
    ip next-hop 10.2.2.2
    interface Serial0/0/1
  Policy routing matches: 0 packets, 0 bytes
```

```cisco
Core#show ip policy
Interface      Route map
Fa0/0          Web_Policy
```

Notice traffic is being forwarded to both servers as expected, and traffic that doesn't match is forwarded as normal.

```cisco
Core#debug ip policy
Policy routing debugging is on
IP: s=192.168.1.2 (FastEthernet0/0), d=10.1.1.2, len 52, FIB policy match
IP: s=192.168.1.2 (FastEthernet0/0), d=10.1.1.2, len 52, PBR Counted
IP: s=192.168.1.2 (FastEthernet0/0), d=10.1.1.2, g=10.1.1.2, len 52, FIB policy routed
IP: s=192.168.1.2 (FastEthernet0/0), d=10.2.2.2, len 47, FIB policy match
IP: s=192.168.1.2 (FastEthernet0/0), d=10.2.2.2, len 47, PBR Counted
IP: s=192.168.1.2 (FastEthernet0/0), d=10.2.2.2, g=10.2.2.2, len 47, FIB policy routed
IP: s=192.168.1.2 (FastEthernet0/0), d=192.168.1.255, len 78, policy rejected -- normal forwarding
```

### Full Configurations

*Click to expand*

<details>
  <summary>> Core</summary>
  <xmp>
hostname Core

! Interface configuration
interface serial 0/0/0
    ip address 10.1.1.1 255.255.255.0
    no shutdown
interface serial 0/0/1
    ip address 10.2.2.1 255.255.255.0
    no shutdown
interface FastEthernet 0/0
    ip address 192.168.1.1 255.255.255.0
    no shutdown

! Configure PBR
ip access-list extended HTTP_Route
    permit tcp any any eq 80
ip access-list extended HTTPS_Route
    permit tcp any any eq 443

route-map Web_Policy 10
    match ip address HTTP_Route
    set ip next-hop 10.1.1.2
    set interface serial 0/0/0
exit
route-map Web_Policy 20
    match ip address HTTPS_Route
    set ip next-hop 10.2.2.2
    set interface serial 0/0/1
exit

interface FastEthernet0/0
    ip policy route-map Web_Policy
</xmp>
</details>

<details>
 <summary>> HTTP-Responder</summary>
<xmp>
hostname HTTP-Responder

! Interface configuration
interface serial 0/0/0
    ip address 10.1.1.2 255.255.255.0
    no shutdown

! Enable routing
ip route  0.0.0.0 0.0.0.0 serial 0/0/0
ip route 10.2.2.2 255.255.255.255 null0

! Configure both HTTP and HTTPS server
username admin privilege 15 secret cisco
ip http server
ip http secure-server
ip http authentication local
</xmp>

</details>

<details>
 <summary>> HTTPS-Responder</summary>
<xmp>
hostname HTTPS-Responder

! Interface configuration
interface serial 0/0/0
    ip address 10.2.2.2 255.255.255.0
    no shutdown

! Enable routing
ip route  0.0.0.0 0.0.0.0 serial 0/0/0
ip route 10.1.1.2 255.255.255.255 null0

! Configure both HTTP and HTTPS server
username admin privilege 15 secret cisco
ip http server
ip http secure-server
ip http authentication local
</xmp>
</details>

## Problems

As mentioned above, route maps can be applied globally or per interface. In this lab, we only applied it on the Fast Ethernet 0/0 interface. This meant HTTP/HTTPS filtering was only occurring on that interface -- not on the serial interfaces. This caused HTTPS traffic destined for the HTTP-Responder to get correctly filtered to the HTTP-Responder router, but because its a *router*, it routed the HTTPS traffic back to the HTTPS-Responder. There are a few ways to resolve this issue.

1. Explicitly deny mismatching traffic (HTTP to the HTTPS-Responder and vis versa).
2. Apply filters the the Serial interface
3. Block traffic between the HTTP-Responder and HTTPS-Responder

This lab used the third option. This is not an optimal option because it blocks *all* traffic between these two routers. Depending on the application, the best solution would be to modify the Route Map to block mismatching traffic from exiting the Core router.

## Conclusion

Policy-based routing gives Network Administrators full control of how traffic is routed in their networks. Although PBR can be used as a way to proxy out different types of traffic, it has many more powerful features that warrant exploration. Future labs might use PBRs to route traffic based on traffic properties and manipulating fields within the packet.

