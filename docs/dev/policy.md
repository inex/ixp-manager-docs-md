# Secure Application Development Policy

INEX has been ISO 27001:2022 Information Security Management System (ISMS) certified since 2023, and the further development of IXP Manager is within the scope of INEX's ISMS *Secure Application Development Policy*. This includes the review and merging of contributions from third parties.

This document outlines how specific requirements in the *Secure Application Development Policy* apply to the development of IXP Manager.

## Security in the Application Development Process

Where possible, we will follow security best practices during the application development process, including:

* **Adoption of secure coding practises** provided by organisations such as [OWASP](https://owasp.org/www-project-top-ten/). In addition to internal knowledge and experience with secure coding practices, the use of recognised application frameworks, including Laravel, helps support this objective.
* Minimisation of attack surface area.
* Separation of duties.
* Employment of the principle of least privileges.
* Use the concept of default deny.
* Validation and sanitisation of input and output data.
* Provision of defence in depth.
* Employment of the 'Keep It Simple' principle.
* Avoidance of security by obscurity.

## Security of the Development Environment

As an open-source project, the protection of intellectual property, the secrecy of source code, etc., do not apply. However, the integrity of the source code is a critical concern. 

INEX uses GitHub for our secure version controlled repository. INEX has vendor-assessed GitHub and deems it suitable for this purpose. GitHub is SOC 3 and SO/IEC 27001:2022 certified and provides [CSA CAIQ](https://cloudsecurityalliance.org/star/registry/github-inc) details.

We employ GitHub's best current practices for the inex/IXP-Manager repository and the inex organisation, including:

* Two-factor authentication using only secure two-factor methods is required for all users.
* Principles of least privileges are applied to repository access.
* Branch protection rules are in place for the master/main and release-* branches. This means that contributors cannot commit code to these branches directly, but rather only via pull requests which a core developer must review.
* [Push protection](https://docs.github.com/en/enterprise-cloud@latest/code-security/secret-scanning/introduction/supported-secret-scanning-patterns#supported-secrets) is enabled for supported secrets.

For internal and third-party developers, we provide [a development database and a Vagrant development environment](https://docs.ixpmanager.org/latest/dev/vagrant/) that contains fake but production-like data. 

## Security in Application Change Control and Secure Coding Practices

IXP Manager development utilises formal change control procedures for any contributions to the code base via GitHub's Pull Request and Review toolchain. Only named core developers can approve pull requests and commit changes to the protected branches. These are currently only Barry O'Donovan and Nick Hilliard.

Anyone may subscribe to be notified of accepted pull requests and/or changes to the protected branches. All core developers receive these notifications. All pull requests, code changes and commit history can be seen on the inex/IXP-Manager GitHub repository by anyone.

On any commit or pull request, [IXP Manager's continuous integration system](https://docs.ixpmanager.org/latest/dev/ci/) runs, which includes:

* Unit testing of the application using the modified code. At the time of writing, this includes 292 tests with 946 assertions. 
* Browser-based unit testing, which performs a thorough and complete test of all CRUD (Create, Read, Update, Delete) actions on the user interface.
* Static code analysis which examines the source code to find potential bugs, security vulnerabilities, and code quality issues.
  
**A new version of IXP Manager requires these continuous integration tests to pass before it can be released.**

Within the team, we employ secure coding practices with specific consideration given to the language, PHP, and the framework, Laravel. Integrated development environments such as PHPStorm or VS Code with PHP extensions are also used which also identify bugs and errors. 

Code reviews include checks for useful and appropriate documentation, as well as the removal of programming defects and legacy code, which can allow information security vulnerabilities to be exploited.


## Outsourced Development Control / Third-Party Contributions

All third-party contributions follow the same methodology outlined above. In addition, third-party contributions are only accepted by individuals or organisations who have [agreed to the contributor license agreement](https://docs.ixpmanager.org/latest/dev/cla/).

## Supply-Chain Security

IXP Manager, like any modern web application, includes third-party libraries for both frontend and backend components. 

We utilise GitHub's [Dependabot](https://docs.github.com/en/code-security/getting-started/dependabot-quickstart-guide) service to notify us about vulnerabilities in the dependencies used in our IXP Manager repository. We also subscribe to appropriate mailing lists and information sources regarding the core languages and frameworks we use.

## Vulnerability Reporting and Responsible Disclosure

We maintain a [security policy](https://github.com/inex/IXP-Manager/security/policy) for vulnerability reporting, utilising GitHub's standard publishing location, where anyone seeking to report an issue would expect to find it. 

