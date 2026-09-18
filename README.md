# AppBaq - Frontend

The graphical user interface and client-side logic for the Azure Quiz (AppBaq) project are delivered by this repository.

## 🌐 The AppBaq Ecosystem & Deployment Order
The project is split across three interconnected repositories. A strict deployment sequence must be followed:
1. **[Infrastructure](https://github.com/thomas-enj/appbaq-infra-terraform):** The Azure cloud resources must be provisioned first.
2. **[Backend](https://github.com/thomas-enj/appbaq-backend):** The database schemas and API services must be deployed second.
3. **[Frontend](https://github.com/thomas-enj/appbaq-frontend):** The user interface must be deployed last (Current Repository).

## 🎯 Scope & Design Choices

The Angular application, its `Dockerfile`, and its `nginx.conf` were supplied as-is by the base repository, which targeted Azure Static Web Apps with an absolute backend URL (see the [inherited documentation](LEGACY_README.md)). The choices made here concern the way the image is published, deployed, and exposed on Azure — including the same-origin `/api` reverse proxy added to `nginx.conf` — and are aligned with those of the infrastructure repository:

| Axis | Choice |
| --- | --- |
| CI/CD tooling | GitHub Actions |
| Deployment target | Azure Kubernetes Service (AKS), through a Helm chart |
| Public exposure | A Kubernetes `LoadBalancer` Service, the only component reachable from the Internet |
| Image registry | The project Azure Container Registry, resolved by tags |
| Backend access | Same-origin `/api` calls, reverse-proxied by Nginx to the in-cluster backend Service |

## 🗺️ Architecture Diagram

> **Status: work in progress.**

The application architecture diagram (draw.io) will be published here, covering the browser entry point, the Nginx reverse proxy, and the call path towards the backend Service inside the cluster.

## 🏗️ Application Architecture
*Note: The core frontend application code and its original documentation were migrated from a separate, pre-existing repository.*

A single page application is built with Angular 22 and TypeScript (`angular.json`, `tsconfig.json`).
* **Web Server:** Once built, the static assets are served by Nginx, configured through `nginx.conf`: a SPA fallback is declared so that client-side routes survive a hard refresh, a `/healthz` endpoint is exposed for the Kubernetes probes, and `/api/` requests are reverse-proxied to the backend Service, since in-cluster DNS names cannot be resolved by a browser.
* **Internationalization:** English and French translations are shipped as static assets under `public/i18n/`.
* **Code Quality & Testing:** Coding standards are enforced by ESLint (`eslint.config.js`) and Prettier (`.prettierrc`), pre-commit hooks are orchestrated by Husky (`.husky/`), and unit tests are executed by Vitest through the Angular CLI test runner.

## 📦 Containerization & Kubernetes Deployment

* **Docker:** The image is produced by the inherited multi-stage `Dockerfile` — the bundle is built on `node:24-alpine`, then served by `nginx:1.30.5-alpine`. Nginx is configured to listen on port 8080 rather than 80, so that the image remains compatible with an unprivileged execution context.
* **Helm Chart:** The Deployment, the Service, and the NetworkPolicies are orchestrated by the chart located in `helm/appbaq-frontend/` and are released into the shared project namespace, next to the backend. Liveness and readiness probes are wired to `/healthz`, and CPU and memory requests and limits are declared.
* **Build-time configuration:** The API base path and the backend API key are baked into the JavaScript bundle at build time through `--build-arg`, since Angular resolves `environment.ts` at compile time. Any change to these values therefore requires a rebuild and a redeployment, not a simple `helm upgrade`.

## 🔐 Network & Secret Management

* **Public entry point:** The Service is of type `LoadBalancer` and forwards port 80 to the container port 8080. The frontend is the only component of the stack exposed to the Internet.
* **Egress restriction:** A NetworkPolicy limits outbound traffic from the frontend pods to the backend pods on port 8080 and to DNS resolution. All other outbound destinations are denied.
* **Backend authentication:** The shared API key is read from the Key Vault by the CI at build time and injected into the image; it is presented on every request as the `X-Api-Key` header expected by the backend.

> **Documented limitation.** Because the key is bundled into client-side JavaScript, it is delivered to the browser and cannot be considered secret from an end user. It is retained as a coarse-grained control that prevents the API from being consumed by third parties without effort, while the actual isolation of the backend is enforced at the network level by the Kubernetes NetworkPolicies.

## 🚀 CI/CD Pipelines & Automation

Manual deployments are entirely bypassed in favor of complete pipeline automation. Both workflows authenticate to Azure through OIDC federated credentials.

* **Build & release preparation (`frontend-release-prep.yml`):** Dependencies are installed, then linting, unit tests, and a production build are executed. The image is built and pushed to the ACR, and a pull request bumping the image tag and the chart version is opened automatically.
* **Deployment (`helm.yml`):** The chart is linted and rendered, then released to AKS with `helm upgrade --install`, and the public URL of the LoadBalancer is printed at the end of the run. Manual `deploy` and `destroy` actions are exposed through `workflow_dispatch`.
* **Resource discovery:** The AKS cluster, the Container Registry, and the Key Vault are resolved at runtime by querying Azure on their tags (`owner`, `environment`, `cohort`, `scope`). No resource name is hard-coded in the pipelines.

## 🛠️ Code Quality & Governance

* **Dependency Management:** NPM packages, Angular dependencies, and GitHub Actions are kept up-to-date automatically by Dependabot (`.github/dependabot.yml`).
* **Code Ownership:** Pull request reviews and code ownership are governed by `.github/CODEOWNERS`.
* **Verified Commits:** Commits are signed so that the *Verified* badge is obtained, and an incremental, prefixed commit history is maintained.
* **Automated Checks:** Application changes are gated by ESLint with `--max-warnings=0`, the unit test suite, and a production build, while chart changes are gated by `helm lint --strict` and a manifest render. Both checks run on pushes and on pull requests. Azure access relies on OIDC federated credentials, so no long-lived credential is stored in the repository.
* **Security Scanning:** Secret detection is delegated to GitHub's native secret scanning, which is enabled on the repository and raises an alert as soon as a credential is pushed. Vulnerable dependencies are reported by Dependabot alerts, and private vulnerability reporting is enabled so that issues can be disclosed responsibly. Code scanning (SAST) has not been set up, and no container image scan is executed by the pipelines.

## 📚 Inherited Application Documentation

This README covers the Azure deployment of the interface. The functional and technical documentation of the application itself was written by the base repository and has been kept unchanged:

👉 **[Read the inherited frontend documentation](LEGACY_README.md)**

> The deployment details mentioned in that document (Azure Static Web Apps, linked backend) describe an earlier target and have been superseded by the AKS setup described above.