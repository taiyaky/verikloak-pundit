# Verikloak Pundit Error Reference

This document summarizes error handling expectations, fallback behaviors, and operational guidance for verikloak-pundit.

## Error Handling Policy
- `Verikloak::Pundit` favors fail-safe behavior: most accessors return `[]` or `nil` instead of raising.
- Authorization failures are delegated to Pundit itself (for example `Pundit::NotAuthorizedError`); this gem does not define custom exception classes.
- Configuration is stored globally. Conflicting settings surface as inconsistent authorization results rather than exceptions inside the gem.

## Typical Failure Scenarios
| Scenario Type | Trigger | Resulting Behavior |
| --- | --- | --- |
| Configuration | `resource_client` or `role_map` is left unset or misconfigured in `Verikloak::Pundit.configure`. | Only role and permission mapping results change; no exception is raised. |
| Configuration | Custom `Proc` objects are assigned to `resource_roles_path` or `realm_roles_path`. | Each segment is coerced with `to_s`; ensure the proc returns a string-compatible value to avoid unexpected dig paths. |
| Configuration | An unknown value is assigned to `permission_role_scope`. | Falls back to the `:default_resource` behavior and continues without raising. |
| JWT Claims | `claims` is `nil` or has an unexpected structure. | `UserContext` falls back to `{}`, so `realm_roles` and `resource_roles` return empty arrays. |
| JWT Claims | `resource_access` is not a Hash or the requested client is missing. | `resource_roles` returns an empty array, causing `has_permission?` to evaluate to `false`. |
| JWT Claims | The `email` claim is missing (and possibly `preferred_username`). | Uses `preferred_username` as a fallback; if that is also missing, returns `nil`. |
| Rack / Rails | `pundit_user` is built from `request.env` but no claims are present. | Returns an empty `UserContext`; no exception is raised. |
| Rack / Rails | Application code reads `verikloak_claims` directly. | `nil` is a valid outcome and should be handled gracefully. |

## Recommended Handling Practices
- Rely on Pundit recovery hooks (e.g. `rescue_from Pundit::NotAuthorizedError`) for authorization failure responses.
- Apply configuration changes during initialization, and when tests mutate global config, reset values in `ensure` blocks to avoid leakage.
- Whenever you customize role mappings, cover the expected permission outcomes with tests to catch unintended grants.

## Operational Security Notes
- `permission_role_scope = :all_resources` を設定すると、`resource_access` に含まれるすべてのクライアントのロールが権限候補になります。アプリ側のアクセス制御ポリシーに照らして不要な権限が含まれないか確認した上で有効化してください。
- `expose_helper_method` を `true` のままにすると `verikloak_claims` をビューから直接参照できるため、個人情報や認可トークンがテンプレートに露出する可能性があります。必要がなければ `false` に変更し、ビューへ渡すデータを最小限にしてください。

## Logging and Debugging Tips
- In Rails, inspect claim payloads with `Rails.logger.debug(request.env[Verikloak::Pundit.config.env_claims_key])`.
- To isolate authorization issues, instantiate `UserContext` directly and inspect `realm_roles`, `resource_roles`, and `has_permission?` outcomes in a console session.

## Known Limitations
- Configuration is not thread-safe; coordinate externally if you must switch settings dynamically in multi-threaded environments.
- The gem does not ship logging or alerting. Add monitoring or notifications in your application layer when required.
