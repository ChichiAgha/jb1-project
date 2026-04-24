# Interview STAR Scenarios

This file is for interview preparation.

It covers the whole project, not just EKS.

The goal is to help you answer questions like:

- what problems came up?
- what risks did you notice?
- how did you solve them?
- how would you explain those decisions in a structured way?

The format used is **STAR**:

- **Situation**
- **Task**
- **Action**
- **Result**

These scenarios include:

1. issues that were directly encountered in the project
2. issues that are very likely to come up in a project like this
3. how to answer them in a senior, structured way

## 1. Local App Was Not Reachable

### Likely interview question

> Tell me about a time a full-stack app was not reachable locally and how you debugged it.

### STAR answer

**Situation**  
I had a Dockerized full-stack application with a React frontend, PHP backend, and PostgreSQL database. At one point, the application URLs were not reachable even though part of the stack existed.

**Task**  
I needed to determine whether the issue was application code, container startup, service readiness, or incorrect infrastructure wiring, and restore a working local environment quickly.

**Action**  
I checked the running containers and confirmed that only PostgreSQL was up while the frontend and backend were missing or not healthy. I brought the stack up properly with a rebuild, then verified container status, backend health, and frontend reachability separately. After that, I made the setup more robust by adding healthchecks and startup dependencies so that services wait for actual readiness rather than only container start order.

**Result**  
The application became reachable again on `localhost`, and the fix improved the reliability of future startups because the stack now has explicit readiness checks instead of relying on timing assumptions.

### Senior interview version

> I treated it as a service orchestration problem, not just a container-start problem. I verified which services were actually alive, confirmed the backend and frontend were missing from the running set, restored the stack, and then hardened it with healthchecks and dependency conditions. That moved the setup from “starts most of the time” to “starts when dependencies are actually ready.”

## 2. Frontend Was Using a Development Container Instead of Production-Style Delivery

### Likely interview question

> Give an example of when you improved an application from a development setup to a production-style setup.

### STAR answer

**Situation**  
The frontend originally ran through the Vite development server inside Docker. That worked for development, but it was not a production-style delivery model and was weaker from an interview and deployment perspective.

**Task**  
I needed to convert the frontend into something more production-oriented without changing the application behavior.

**Action**  
I replaced the development-container approach with a multi-stage Docker build. The first stage used Node to install dependencies and build the Vite assets, and the second stage used Nginx to serve only the static compiled files. I also added an Nginx config to handle SPA routing and proxy `/api` requests to the backend.

**Result**  
The frontend became smaller, cleaner, and more production-like. It no longer depended on the Vite dev server at runtime, and the deployment story became much stronger for interviews because the container now reflects how a real frontend would typically be served.

### Senior interview version

> The original setup was operationally valid for development but not a strong runtime model. I moved it to a build-stage plus runtime-stage pattern so that Node is only used for compilation and Nginx is the serving layer. That reduced runtime complexity, improved immutability of the frontend artifact, and gave the project a more defensible production posture.

## 3. Dependency Installation Needed to Be Reproducible

### Likely interview question

> Why did you choose `npm ci` instead of `npm install` in Docker?

### STAR answer

**Situation**  
The frontend image build initially used the common `npm install` pattern, which is fine for local development but less ideal for deterministic container builds.

**Task**  
I needed to make the image build more reproducible and more aligned with CI/CD expectations.

**Action**  
I switched the Docker build step to `npm ci`, which installs dependencies exactly from the lockfile and starts from a clean dependency state. I kept the explanation clear so the difference between development installs and CI installs was explicit.

**Result**  
The frontend build became more predictable, which is especially important in containers and CI pipelines, because the image build is now tied directly to the committed lockfile.

### Senior interview version

> I changed the build to `npm ci` because containers and CI should be deterministic. I wanted the image to reflect the lockfile exactly rather than allow incidental dependency drift during installation. That’s a small change, but it materially improves reproducibility.

## 4. Database Schema Was Created Inside Request Flow

### Likely interview question

> Describe a time you improved database initialization or schema management.

### STAR answer

**Situation**  
The backend originally created its database table as part of normal request handling. That is acceptable for a tiny demo, but it is not a good production practice because schema creation should not be hidden inside application runtime flow.

**Task**  
I needed to move schema management into an explicit, versionable process.

**Action**  
I introduced SQL migrations and a migration runner. I moved schema creation out of request handling and into a dedicated migration step that runs before the backend server starts.

**Result**  
Database setup became explicit, repeatable, and easier to reason about. That improved the project technically and gave a much stronger interview explanation around schema lifecycle management.

### Senior interview version

> I replaced runtime schema side effects with migrations because database shape should be versioned infrastructure, not implicit application behavior. That creates a cleaner contract between application startup and data-layer evolution.

## 5. Basic Availability Checks Were Not Enough

### Likely interview question

> How did you improve reliability in the Docker setup?

### STAR answer

**Situation**  
At first, the containers could be started, but that did not guarantee the services were actually ready. In distributed systems, “container started” and “service ready” are not the same thing.

**Task**  
I needed to make service startup more reliable and reduce timing-related failures.

**Action**  
I added healthchecks for PostgreSQL, the backend, and the frontend. Then I used those healthchecks to define startup dependencies so the backend waits for a healthy database and the frontend waits for a healthy backend.

**Result**  
The stack became more stable and less timing-sensitive. Instead of hoping dependencies were available, the containers now wait for confirmed readiness.

### Senior interview version

> I moved the Compose setup from simple process orchestration to readiness-aware orchestration. That reduces false starts and makes the environment much more deterministic, especially for local demos and CI runs.

## 6. The Database Was Exposed More Than Necessary

### Likely interview question

> Tell me about a security improvement you made in the project.

### STAR answer

**Situation**  
The database did not need to be publicly exposed to the host in order for the application to function, because only the backend container needed to reach it.

**Task**  
I needed to reduce unnecessary exposure without breaking connectivity.

**Action**  
I removed the public Postgres port mapping and kept PostgreSQL internal to the Docker network. The backend still reached it through Docker DNS using the service name.

**Result**  
The database remained fully functional for the application while reducing unnecessary host-level exposure. It was a simple but meaningful hardening step.

### Senior interview version

> I applied least-exposure rather than default exposure. The database was not a user-facing dependency, so there was no reason to publish it to the host interface. Internal-only networking was the more defensible choice.

## 7. Needed Better Confidence Than “It Starts”

### Likely interview question

> How did you validate the app beyond manually opening it in a browser?

### STAR answer

**Situation**  
The application could start successfully, but a running stack is not the same as a validated stack. I needed a way to verify both service reachability and backend behavior consistently.

**Task**  
I needed fast checks for both health and CRUD behavior.

**Action**  
I added a smoke test script to validate frontend loading, backend health, API proxying, and task endpoint reachability. I also added a CRUD test script that verifies create, list, update, delete, and expected failure behavior.

**Result**  
I had lightweight but meaningful verification for both local use and automation. That improved confidence and made the CI pipeline much more useful.

### Senior interview version

> I introduced layered verification: smoke tests for service-level health and CRUD tests for application behavior. That gave me better signal than manual verification alone without requiring a heavy testing framework for a small project.

## 8. CI Needed to Check the Whole Delivery Path

### Likely interview question

> What did your CI pipeline actually validate?

### STAR answer

**Situation**  
Once the project had container builds, migrations, and tests, it needed automated validation so changes could be checked consistently before merge or release.

**Task**  
I needed CI to validate buildability, orchestration, and application behavior, not just syntax.

**Action**  
I created a GitHub Actions pipeline that validates Docker Compose configuration, builds the stack, waits for service health, runs smoke tests, and runs the CRUD API test suite.

**Result**  
CI became a real quality gate. It verifies that the stack can build and that the core application flow still works, not just that the repository contains valid YAML or Dockerfiles.

### Senior interview version

> I wanted CI to validate the system path, not only individual files. So the pipeline checks Compose validity, builds the containers, waits for readiness, and exercises the application through smoke and CRUD tests. That gives a more realistic signal about whether the change is operationally safe.

## 9. CD Needed the Right Scope for Project 0

### Likely interview question

> What did CD mean in this project, and what did it not mean?

### STAR answer

**Situation**  
The project needed a CD story, but the scope had to match the maturity of the application and the stage of the project.

**Task**  
I needed to define CD at an appropriate level without overstating it.

**Action**  
I implemented basic container delivery rather than full runtime deployment. The workflow builds images, tags them, and pushes them to a registry after validation passes. I explicitly did not present it as Kubernetes deployment, Argo CD, or rollout orchestration.

**Result**  
The project has a credible CD story that matches its maturity: validated images are produced and published, ready for deployment to a future runtime environment.

### Senior interview version

> I scoped CD intentionally. At this stage, CD means artifact delivery, not full production rollout. The pipeline validates the stack, builds versioned images, and publishes them to the registry. That is a disciplined Project 0 boundary and avoids pretending the project has a deployment platform it does not yet have.

## 10. Secrets Needed Basic Cleanup

### Likely interview question

> How did you handle secrets and environment values?

### STAR answer

**Situation**  
The project needed to show environment-driven configuration without committing real secrets into the repository.

**Task**  
I needed to document required variables, keep local development simple, and avoid treating placeholder values as real secret management.

**Action**  
I added `.env.example` files, ignored local `.env` files in Git, and used environment-variable defaults for local development. I also documented that real production secrets should come from GitHub Actions or the hosting environment rather than the repo.

**Result**  
The project became cleaner and more realistic. It now documents required values clearly while avoiding committed local secrets, and it leaves a clear path for production secret injection later.

### Senior interview version

> I implemented basic secret hygiene rather than pretending the project had enterprise secret management. The repo now documents environment contracts through example files, ignores real local values, and expects real secret injection to come from CI or the runtime platform.

## 11. Terraform Needed Better Environment and State Separation

### Likely interview question

> Why did you structure Terraform with separate folders and state keys?

### STAR answer

**Situation**  
For the infrastructure side, a flat Terraform layout would have been easier to start with, but it would not reflect how environment separation and stack ownership usually work in a more mature setup.

**Task**  
I needed to build a live-style structure that supports multiple environments and modular state.

**Action**  
I organized AWS into `development`, `sandbox`, and `production`, and split each environment into `s3-backend`, `vpc`, `ecr`, `ec2/app`, and `eks`. Each stack got its own backend key so state is separated by concern.

**Result**  
The infrastructure layout became closer to how platform teams manage Terraform in practice. It is easier to reason about, safer to change incrementally, and much easier to explain in an interview.

### Senior interview version

> I optimized for separation of concern and state hygiene. Each environment is explicit, and each stack owns a clear domain. That means smaller plans, smaller blast radius, and clearer dependency direction across the live repo.

## 12. Shared Modules vs Local Modules Needed a Clear Boundary

### Likely interview question

> Why did some Terraform stacks use shared Git modules while another used a local module?

### STAR answer

**Situation**  
The live Terraform layout needed to mirror the organization’s module pattern where possible, but not every required stack shape already existed in the shared module repository.

**Task**  
I needed to mirror the reference structure accurately without forcing an incorrect abstraction.

**Action**  
I updated the VPC, ECR, S3 backend, and EKS stacks to point to the shared Git modules from the organization module repository. For the EC2 application layer, I kept a local module because there was no equivalent shared ALB plus ASG module that matched the project’s needs.

**Result**  
The implementation mirrors the shared-module model where it should, while staying honest and pragmatic where a project-specific module was necessary.

### Senior interview version

> I mirrored shared modules where a stable organizational abstraction already existed, and I used a local module where the application-hosting composition was project-specific. That preserves reuse without introducing a poor abstraction simply for the sake of uniformity.

## 13. EKS Needed to Be Explained as a Platform Layer, Not Just a Cluster

### Likely interview question

> Tell me about the EKS design and why it is one of your stronger areas.

### STAR answer

**Situation**  
The EKS stack was the most platform-oriented part of the infrastructure because it combines networking, cluster provisioning, IAM-based access, and optional add-on services.

**Task**  
I needed to structure it so it was modular, understandable, and aligned with the rest of the live Terraform design.

**Action**  
I kept EKS in its own state, read VPC outputs from remote state, separated control plane and node groups, and modeled add-ons like storage, autoscaling, and load balancer integration as optional modules.

**Result**  
The stack became a strong example of platform engineering structure rather than just resource creation. It is one of the strongest interview areas because it shows both infrastructure composition and operational reasoning.

### Senior interview version

> I treated EKS as a platform layer with explicit module boundaries for control plane, worker capacity, auth, and add-ons. The design reuses VPC outputs cleanly, keeps state isolated, and makes cluster capabilities explicit instead of hiding them in one monolithic cluster definition.

## 14. Azure Needed to Stay Compact Without Looking Shallow

### Likely interview question

> Why was Azure smaller than AWS, and how did you position that well?

### STAR answer

**Situation**  
The project needed both AWS and Azure, but AWS was the primary implementation. Trying to build both clouds to identical depth would have diluted the quality of the main design.

**Task**  
I needed Azure to be credible and equivalent in concept without making it unnecessarily large.

**Action**  
I built Azure as a compact modular stack using a resource group module, a network module, and an app module. That covered the core ideas: network separation, NAT, security groups equivalent through NSGs, an Application Gateway, and a VM Scale Set.

**Result**  
Azure became a valid compact equivalent of the AWS design. It demonstrates multi-cloud understanding while keeping AWS as the deeper platform story.

### Senior interview version

> I scoped Azure deliberately. AWS is the deep implementation; Azure is the compact equivalent. The goal was to demonstrate translation of platform design patterns across clouds without pretending both clouds needed identical depth for the same project stage.

## 15. Public vs Private Network Boundaries Had to Be Explained Clearly

### Likely interview question

> How did you separate public and private traffic in your infrastructure?

### STAR answer

**Situation**  
The infrastructure needed clear ingress and workload boundaries rather than a flat network where everything was equally reachable.

**Task**  
I needed to ensure internet-facing entry points were public while workload execution stayed private.

**Action**  
In AWS, I placed the ALB in public subnets and the EC2 compute layer in private subnets. In Azure, I used an Application Gateway as the public-facing entry point and placed the VM Scale Set behind it in private network space. NAT was used for outbound access from private compute.

**Result**  
The topology became closer to a real production hosting pattern and easier to defend from both a security and architecture perspective.

### Senior interview version

> I separated edge and workload layers explicitly. Public-facing load-balancing components sit in the ingress tier, while workload capacity sits in private address space with controlled outbound access. That gives a clearer security boundary and a more production-aligned topology.

## 16. How to Answer If Asked “What Was the Hardest Part?”

### Strong answer

> The hardest part was keeping the project honest while still making it interview-strong. There is a temptation to overstate maturity, but I wanted the setup to be technically defensible. So I separated what was truly implemented, like modular CI, migrations, live-style Terraform layout, and image publishing, from what was only planned for later, like full deployment infrastructure and more advanced production operations.

## 17. How to Answer If Asked “What Would You Improve Next?”

### Strong answer

> On the application side, I would deepen automated tests and refine deployment targeting. On the infrastructure side, I would validate Terraform end to end against real cloud credentials and strengthen the operational story around deployment, secrets, and runtime observability. The structure is already there; the next step is environment-backed validation and operational hardening.

## 18. Fast STAR Answers You Can Memorize

### Reliability

> I noticed that container startup order did not guarantee service readiness, so I added healthchecks and readiness-based dependencies. That made local startup and CI much more deterministic.

### Security

> I removed unnecessary database exposure and kept PostgreSQL internal to the Docker network, which reduced surface area without changing application behavior.

### Delivery

> I changed the frontend from a dev-server container to a multi-stage build served by Nginx, which made the runtime artifact more production-like and easier to justify in an interview.

### Data

> I moved schema creation out of request flow and into migrations so database structure became explicit and versioned.

### Infrastructure

> I split Terraform by environment and concern, with separate state keys, so the layout is closer to a live platform repo and easier to change safely.

### Platform

> I modeled EKS as a platform layer with remote-state-driven VPC reuse, separate control plane and node groups, and optional add-ons for capabilities like storage, autoscaling, and ingress integration.

## 19. Top 10 Answers To Memorize

These are the highest-value answers to remember if you need concise, strong interview responses.

### 1. Tell me about the project

> I built a Dockerized full-stack task application with a React frontend, a PHP backend, and PostgreSQL, then strengthened it with migrations, smoke and CRUD tests, CI, basic CD image publishing, and a modular Terraform infrastructure layout for AWS and Azure.

### 2. What was one meaningful reliability improvement you made?

> I added healthchecks and readiness-based startup dependencies because container start order alone does not guarantee service readiness. That made the stack more deterministic both locally and in CI.

### 3. What was one meaningful production-style improvement you made?

> I replaced the frontend dev-server container with a multi-stage Docker build that compiles the Vite app and serves the static output through Nginx. That made the runtime smaller, cleaner, and more production-like.

### 4. Why did you use `npm ci` in Docker?

> I used `npm ci` because container and CI builds should be deterministic. It installs exactly from the lockfile, which reduces dependency drift and makes builds reproducible.

### 5. Why did you add migrations?

> I moved schema creation out of request flow and into migrations so database structure became explicit, versioned, and easier to manage safely across environments.

### 6. What does your CI pipeline validate?

> CI validates the system path, not just file syntax. It checks Docker Compose configuration, builds the stack, waits for health, and runs smoke and CRUD tests so I know the app actually starts and behaves correctly.

### 7. What does CD mean in this project?

> At this stage, CD means validated container delivery. The workflow builds versioned images and pushes them to the registry after checks pass. It does not pretend to be full runtime deployment yet.

### 8. Why did you structure Terraform the way you did?

> I structured Terraform like a live repo, with separate environments and separate state per concern, so networking, registries, compute, and EKS can evolve independently with smaller blast radius and clearer ownership boundaries.

### 9. Why is EKS one of your strongest areas?

> EKS is where infrastructure, networking, IAM, cluster design, and platform add-ons come together. I can explain not just how the cluster is provisioned, but why the control plane, node groups, auth, storage, ingress, and autoscaling concerns are modeled separately.

### 10. Why is Azure smaller than AWS in this project?

> AWS is the deep implementation and Azure is the compact equivalent. I used Azure to show I can translate the same infrastructure ideas across clouds without diluting the depth of the primary AWS design.

## 20. Trap Questions And Safe Answers

These are questions interviewers may use to check whether you are overstating the implementation.

The goal is not to dodge. The goal is to answer honestly while still sounding technically strong.

### Trap 1: “Did you actually deploy all of this to AWS and Azure?”

Safe answer:

> I implemented the Terraform structure, stack boundaries, module wiring, and state layout, and I validated the code organization locally. Full cloud runtime validation still depends on real credentials, backend configuration, and access to the shared Git modules, so I would describe the implementation honestly as structurally complete with environment-backed validation still required.

Why this works:

- honest
- clear
- not defensive
- still shows ownership of the design

### Trap 2: “So is this fully production-ready?”

Safe answer:

> I would call it production-style rather than fully production-ready. The structure is strong: modular containers, healthchecks, migrations, CI, image publishing, and live-style Terraform separation. Full production readiness would still require environment-backed deployment validation, stronger observability, more complete secret management, and a hardened runtime operating model.

Why this works:

- you do not oversell
- you show you understand what “production-ready” really means

### Trap 3: “Did CD actually deploy to running infrastructure?”

Safe answer:

> In this project stage, CD means validated image delivery rather than full runtime rollout. The workflow builds, tags, and pushes images after checks pass. I kept that scope deliberate so the pipeline matched the maturity of the project rather than pretending deployment automation already existed.

Why this works:

- keeps scope honest
- shows deliberate engineering judgment

### Trap 4: “If the app runs on EC2, why are you also building EKS?”

Safe answer:

> The EC2 path and the EKS path serve different purposes in the project. The EC2 stack demonstrates a straightforward ALB plus Auto Scaling hosting model. The EKS stack demonstrates how I structure a Kubernetes platform layer. I would not present them as two simultaneous production runtimes for the same app without an explicit reason; they are two infrastructure patterns built to demonstrate capability.

Why this works:

- avoids pretending the app is actively deployed both ways
- shows you understand architectural intent

### Trap 5: “Did you really mirror the live repo exactly?”

Safe answer:

> I mirrored the live-repo pattern closely for environment layout, backend separation, and shared Git module sourcing where the shared modules already existed, such as VPC, ECR, S3 backend, and EKS. For the ALB plus ASG application layer, I used a local module because there was no equivalent shared module for that exact composition, so I would describe that part as aligned with the pattern rather than an exact one-to-one copy.

Why this works:

- precise
- defensible
- shows you know exactly where the deviations are

### Trap 6: “How much of this was copied versus designed?”

Safe answer:

> I used existing patterns intentionally where they were the right abstraction, especially in the shared Terraform module model. The design work was in structuring the live stacks, choosing the boundaries, wiring the dependencies, aligning the inputs, and filling the gaps where a project-specific module was needed. Reuse was part of the design, not a substitute for it.

Why this works:

- shows maturity
- frames reuse as good engineering, not weakness

### Trap 7: “Did you test the Terraform end to end?”

Safe answer:

> I validated the structure, backend separation, and module wiring locally, but a full end-to-end Terraform validation still depends on real cloud credentials, real backend state, and reachable shared Git modules. I would not claim a full apply where that environment-backed validation has not happened yet.

Why this works:

- you stay truthful
- you still sound in control

### Trap 8: “Why didn’t you just put everything in one Terraform stack?”

Safe answer:

> I split it because state boundaries are an architectural decision, not just a file-layout choice. Networking, registries, compute, and EKS have different lifecycles and different failure domains. Separate stacks make plans smaller, reduce blast radius, and create cleaner dependency direction through remote state.

Why this works:

- strong platform-engineering answer
- explains the design principle, not just preference

### Trap 9: “Why did you keep some bootstrap logic in infrastructure modules?”

Safe answer:

> For this project, I kept some instance and VM bootstrap assumptions because I wanted the infrastructure to reflect a runnable hosting path rather than stop at empty compute. I would be clear, though, that this is no longer pure infrastructure-only provisioning once startup scripts are included.

Why this works:

- shows honesty about scope
- shows you understand infra/application boundary tradeoffs

### Trap 10: “What would break first if I handed this to a real production team?”

Safe answer:

> The first gap would be environment-backed operational validation. Structurally the project is in good shape, but a real production team would expect deployment-target validation, stronger observability, stricter secret handling, and clearer ownership of runtime operations beyond code structure alone.

Why this works:

- mature answer
- no pretending
- shows you understand the difference between good architecture and fully operated systems

## 21. One Rule To Remember In The Interview

If you are unsure how to answer, use this rule:

> Be precise about what was implemented, be clear about what was intentionally scoped, and be explicit about what would be the next production step.

That keeps your answers strong without overselling.
