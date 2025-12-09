# Changelog

## [1.3.1](https://github.com/gocloudLa/terraform-aws-wrapper-ecs-service/compare/v1.3.0...v1.3.1) (2025-12-09)


### Bug Fixes

* **secrets:** generate SECRETS_MD5 per container to prevent restarts ([#18](https://github.com/gocloudLa/terraform-aws-wrapper-ecs-service/issues/18)) ([b511dc8](https://github.com/gocloudLa/terraform-aws-wrapper-ecs-service/commit/b511dc86faa431d2511cf080d589e7299ab58e6c))

## [1.3.0](https://github.com/gocloudLa/terraform-aws-wrapper-ecs-service/compare/v1.2.0...v1.3.0) (2025-11-19)


### Features

* **module:** add multi port support in lb ecs services ([#16](https://github.com/gocloudLa/terraform-aws-wrapper-ecs-service/issues/16)) ([3d85c46](https://github.com/gocloudLa/terraform-aws-wrapper-ecs-service/commit/3d85c469a784ecb04537cc5a4aa242f06badfc60))

## [1.2.0](https://github.com/gocloudLa/terraform-aws-wrapper-ecs-service/compare/v1.1.0...v1.2.0) (2025-11-07)


### Features

* **ecs:** add nlb attach ([#13](https://github.com/gocloudLa/terraform-aws-wrapper-ecs-service/issues/13)) ([a0954a6](https://github.com/gocloudLa/terraform-aws-wrapper-ecs-service/commit/a0954a64a232c8b56aa75187856f4f8d94573cc8))


### Bug Fixes

* **alarms:** refactor alarm creations ([#9](https://github.com/gocloudLa/terraform-aws-wrapper-ecs-service/issues/9)) ([415b849](https://github.com/gocloudLa/terraform-aws-wrapper-ecs-service/commit/415b849f567a92cb489812361057c404ebc8e3d5))
* **ecs:** example capacity provider and change default ([#8](https://github.com/gocloudLa/terraform-aws-wrapper-ecs-service/issues/8)) ([d1742b6](https://github.com/gocloudLa/terraform-aws-wrapper-ecs-service/commit/d1742b64f143d3fbe7721fbe8460683636dd2782))
* **ecs:** example comment ([#14](https://github.com/gocloudLa/terraform-aws-wrapper-ecs-service/issues/14)) ([00971c1](https://github.com/gocloudLa/terraform-aws-wrapper-ecs-service/commit/00971c19a8b60407093ba7652db9a70a4d205164))
* **ssm:** add overwrite = true ([#12](https://github.com/gocloudLa/terraform-aws-wrapper-ecs-service/issues/12)) ([664e39b](https://github.com/gocloudLa/terraform-aws-wrapper-ecs-service/commit/664e39bcd4f49428b65de5c44e4a9eb5fec6ace6))

## [1.1.0](https://github.com/gocloudLa/terraform-aws-wrapper-ecs-service/compare/v1.0.1...v1.1.0) (2025-10-12)


### Features

* **alarms:** add capacity unavailable alarm ([#4](https://github.com/gocloudLa/terraform-aws-wrapper-ecs-service/issues/4)) ([3650695](https://github.com/gocloudLa/terraform-aws-wrapper-ecs-service/commit/36506957de99b783439b8cfee1bfd2dae0f82cbb))


### Bug Fixes

* **deps:** bump terraform-aws-modules/ecr/aws from 3.0.1 to 3.1.0 in the all-terraform-dependencies group across 1 directory ([#6](https://github.com/gocloudLa/terraform-aws-wrapper-ecs-service/issues/6)) ([c13d9ab](https://github.com/gocloudLa/terraform-aws-wrapper-ecs-service/commit/c13d9ab7a0ddd783b5b4442c0f6c787180bb3769))

## [1.0.1](https://github.com/gocloudLa/terraform-aws-wrapper-ecs-service/compare/v1.0.0...v1.0.1) (2025-09-18)


### Bug Fixes

* **terraform:** external modules upgrade 20250910 ([47e8874](https://github.com/gocloudLa/terraform-aws-wrapper-ecs-service/commit/47e8874a8e2f9349420de7a0c0129965a289c382))

## 1.0.0 (2025-09-05)


### Features

* **ci:** Add Dependabot configuration. ([c25125d](https://github.com/gocloudLa/terraform-aws-wrapper-ecs-service/commit/c25125d733b43afbf6fe7fa4e23316ec52448d5e))
* **ci:** Add Dependabot configuration. ([d4abd0c](https://github.com/gocloudLa/terraform-aws-wrapper-ecs-service/commit/d4abd0c69de28004f26951f277d9defd925a0430))
* **module:** initial release ([#1](https://github.com/gocloudLa/terraform-aws-wrapper-ecs-service/issues/1)) ([00e5987](https://github.com/gocloudLa/terraform-aws-wrapper-ecs-service/commit/00e59872ad6f32f9040f9c17dbb2b571f8f1d508))


### Miscellaneous Chores

* release 1.0.0 ([adcc477](https://github.com/gocloudLa/terraform-aws-wrapper-ecs-service/commit/adcc477ff168505259ef8c2d721db6ea0deb7934))
