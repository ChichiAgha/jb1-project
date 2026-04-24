# EKS Mock Interview

This file is a mock interview set focused only on the EKS part of the infrastructure.

It does not replace the earlier READMEs.

Use it to practice:

- short answers
- deeper senior-level answers
- follow-up tradeoff discussion

Main reference stack:

- [infra-live/aws/development/eks/main.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development/eks/main.tf:1)

Supporting files:

- [providers.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development/eks/providers.tf:1)
- [data.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development/eks/data.tf:1)
- [locals.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development/eks/locals.tf:1)
- [variables.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development/eks/variables.tf:1)
- [outputs.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development/eks/outputs.tf:1)

## 1. Tell me about your EKS implementation

### Short answer

> I implemented EKS as its own Terraform stack with separate remote state. The stack reads VPC outputs from remote state, creates the EKS control plane and managed node groups, and then conditionally adds cluster components like aws-auth, storage classes, the load balancer controller, autoscaler, metrics server, and namespaces.

### Stronger answer

> I treated EKS as a platform layer, not just a cluster resource. The stack is modular: control plane, node groups, auth, storage, and add-ons are separated into dedicated modules. It consumes networking through the VPC stack’s remote state, which keeps networking authoritative in one place. That lets the cluster stack stay focused on Kubernetes platform concerns rather than duplicating subnet or VPC logic.

### What the interviewer is looking for

- can you explain EKS beyond “I created a cluster”
- do you understand separation of concerns
- do you understand how EKS depends on networking

## 2. Why did you put EKS in its own state file?

### Good answer

> EKS has a different lifecycle from VPC, ECR, or application load balancing. Keeping it in its own state reduces blast radius, makes plans easier to review, and lets me change cluster-level concerns without re-planning the entire infrastructure stack.

### Senior version

> EKS state tends to be noisier and more operationally active than foundational network state. If I mixed it with VPC state, I would increase risk and reduce clarity. A dedicated state boundary makes dependency direction explicit: VPC exports, EKS consumes.

## 3. Why use remote state from the VPC stack?

### Good answer

> The cluster needs the VPC ID and subnet IDs, but networking should still be owned by the VPC stack. Remote state lets the EKS stack consume those outputs without hardcoding IDs or recreating the network.

### Senior version

> Remote state is acting as a contract boundary. The VPC stack publishes outputs like `vpc_id` and `private_subnets`, and the EKS stack consumes them. That gives me loose coupling with explicit dependency, which is cleaner than duplicating CIDR logic or passing around manually copied IDs.

## 4. Why are the worker nodes in private subnets?

### Good answer

> Private subnets are the right default for production-oriented compute. The nodes do not need direct public exposure. They can still make outbound calls through NAT, while inbound traffic is controlled through Kubernetes ingress patterns or AWS load balancing integrations.

### Senior version

> Keeping nodes in private subnets improves network posture. It reduces unnecessary exposure, preserves a clearer trust boundary, and aligns with the model where internet-facing traffic terminates at controlled entry points rather than directly at worker nodes.

## 5. What is the difference between the EKS control plane and node groups?

### Good answer

> The control plane is the managed Kubernetes API layer provided by AWS. Node groups are the EC2 worker nodes that actually run pods. Terraform creates both, but they are separate concerns and should be modeled separately.

### Senior version

> The control plane handles cluster orchestration, API availability, and managed Kubernetes control logic, while node groups provide workload capacity. Splitting them in Terraform is important because they scale, upgrade, and fail differently, and platform add-ons usually depend on node readiness rather than just control plane creation.

## 6. Why did you use modules instead of one large `main.tf`?

### Good answer

> Different parts of the cluster change at different rates. Control plane, node groups, auth, storage, and add-ons are distinct concerns. Using modules makes the stack easier to maintain and easier to reason about.

### Senior version

> A monolithic cluster file hides lifecycle boundaries. Module composition makes optional components explicit, keeps interfaces cleaner, and makes future change safer. It also scales better when different teams or workflows own different parts of platform configuration.

## 7. What does `aws_auth_config` do?

### Good answer

> It manages the AWS auth mapping layer for EKS, which is how AWS IAM identities get access into the Kubernetes cluster.

### Senior version

> EKS authentication starts from AWS IAM. The aws-auth layer bridges IAM principals into Kubernetes access. Treating that as an explicit module is important because cluster access is a security boundary, not just a convenience setting.

## 8. Why did you make some add-ons optional?

### Good answer

> Not every cluster needs every add-on at the same time. Making them optional keeps the stack flexible and easier to reuse.

### Senior version

> Optional add-ons are controlled through feature flags because cluster capabilities should be explicit. This prevents hidden platform behavior and allows cleaner staged rollout of cluster services like metrics, autoscaling, or ingress controllers.

## 9. What does the AWS Load Balancer Controller do in EKS?

### Good answer

> It lets Kubernetes resources work with AWS load balancers, especially for ingress-related traffic management.

### Senior version

> The AWS Load Balancer Controller translates Kubernetes ingress and service intent into AWS load balancer resources. It is the control-plane bridge between Kubernetes application exposure and AWS-native L7/L4 load balancing.

## 10. What is the EBS CSI driver for?

### Good answer

> It provides persistent storage integration for Kubernetes workloads that need volumes backed by EBS.

### Senior version

> The EBS CSI driver is the modern storage integration path for EKS. It allows persistent volume provisioning and attachment through the CSI model, which is the right abstraction for Kubernetes-native storage operations.

## 11. What is the metrics server for?

### Good answer

> It exposes resource metrics inside the cluster, which are used by things like autoscaling and operational visibility.

### Senior version

> The metrics server is foundational for resource-based Kubernetes decisions. Without it, autoscaling and some operational tooling lose access to the metrics APIs they depend on.

## 12. What is cluster autoscaler and how is it different from HPA?

### Good answer

> Cluster autoscaler adds or removes nodes based on unschedulable pods and overall cluster capacity. HPA scales pods. One scales infrastructure capacity, the other scales application replicas.

### Senior version

> HPA and cluster autoscaler solve different layers of elasticity. HPA adjusts workload replica counts based on metrics. Cluster autoscaler adjusts node capacity when scheduling pressure exceeds current cluster resources. In a production setup, they usually complement each other.

## 13. Why use object variables in the EKS stack?

### Good answer

> They keep related settings grouped together, which makes the module interface cleaner and easier to review.

### Senior version

> Object variables make the module contract more coherent. Instead of scattering cluster settings across many flat variables, I can group control plane config, node group config, and add-on config into explicit interfaces that are easier to validate, review, and evolve.

## 14. Why are `kubernetes` and `helm` providers in the same stack?

### Good answer

> Because after Terraform creates the cluster, it also needs to configure things inside the cluster, such as add-ons and platform components.

### Senior version

> The stack spans both infrastructure provisioning and cluster-level platform configuration. Using `kubernetes` and `helm` providers lets Terraform bootstrap cluster services after the control plane becomes available, although it does increase coupling to cluster readiness and provider auth flow.

## 15. What tradeoff comes with managing cluster add-ons in Terraform?

### Good answer

> It is convenient because one workflow manages both infrastructure and add-ons, but it also means Terraform depends more on cluster health and provider access.

### Senior version

> The advantage is unified provisioning and explicit configuration. The tradeoff is tighter operational coupling: if provider auth, cluster connectivity, or API availability breaks, Terraform runs can become more fragile. At scale, some teams move certain cluster add-ons into GitOps or dedicated platform workflows for that reason.

## 16. Why is EKS your strongest point?

### Good answer

> Because it brings together infrastructure, IAM, networking, cluster operations, and platform add-ons in one design. It is the area where I can explain both the implementation and the reasoning behind the implementation.

### Strong answer

> It is the strongest point because it sits at the intersection of cloud infrastructure and platform engineering. I’m comfortable explaining why the VPC is consumed through remote state, why control plane and node groups are separated, why platform features are modeled as optional modules, and how cluster access, ingress, storage, and autoscaling fit together operationally.

## 17. What would you improve next in this EKS stack?

### Good answer

> I would validate the modules end to end with real AWS credentials and environment values, review the upgrade strategy, and tighten the operational model around add-on lifecycle and cluster access management.

### Strong answer

> Next I would focus on runtime validation, version pinning discipline, upgrade strategy for both control plane and node groups, and a clear operating model for which add-ons stay in Terraform versus moving into a GitOps flow. I would also review security hardening around IAM roles, logging, and cluster network policy.

## 18. If the interviewer pushes: “Did you actually deploy it?”

### Honest answer

> I implemented the stack structure and module wiring and mirrored the shared module pattern, but full runtime validation still depends on AWS credentials, the remote state backend, and access to the shared Git module sources. So the design and code structure are in place, but I would describe final deployment validation honestly based on the target environment.

That is the right answer. Do not bluff.

## 19. Good closing answer for EKS

If you need one compact, senior-sounding answer:

> I designed EKS as a separate Terraform platform stack that consumes VPC outputs from remote state, provisions the control plane and managed node groups, and composes optional cluster capabilities such as storage, ingress integration, metrics, and autoscaling through dedicated modules. The design keeps state boundaries clean, keeps networking authoritative in one place, and models Kubernetes platform concerns explicitly rather than hiding them in a single cluster definition.

## 20. Practice drill

If you want a fast self-test, answer these without looking:

1. Why is EKS in its own state file?
2. Why does EKS read VPC remote state?
3. Why are nodes in private subnets?
4. Why separate control plane and node groups?
5. Why are add-ons optional?
6. What does the load balancer controller do?
7. How is cluster autoscaler different from HPA?
8. Why use object variables?
9. What is the tradeoff of using Helm/Kubernetes providers in Terraform?
10. What would you improve next?

If you can answer those cleanly, you can defend the EKS stack well.
