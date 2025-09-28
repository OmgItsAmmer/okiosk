| table_schema | table_name                 | column_name                 | data_type                   | is_nullable | column_default                                           |
| ------------ | -------------------------- | --------------------------- | --------------------------- | ----------- | -------------------------------------------------------- |
| auth         | audit_log_entries          | instance_id                 | uuid                        | YES         | null                                                     |
| auth         | audit_log_entries          | id                          | uuid                        | NO          | null                                                     |
| auth         | audit_log_entries          | payload                     | json                        | YES         | null                                                     |
| auth         | audit_log_entries          | created_at                  | timestamp with time zone    | YES         | null                                                     |
| auth         | audit_log_entries          | ip_address                  | character varying           | NO          | ''::character varying                                    |
| auth         | flow_state                 | id                          | uuid                        | NO          | null                                                     |
| auth         | flow_state                 | user_id                     | uuid                        | YES         | null                                                     |
| auth         | flow_state                 | auth_code                   | text                        | NO          | null                                                     |
| auth         | flow_state                 | code_challenge_method       | USER-DEFINED                | NO          | null                                                     |
| auth         | flow_state                 | code_challenge              | text                        | NO          | null                                                     |
| auth         | flow_state                 | provider_type               | text                        | NO          | null                                                     |
| auth         | flow_state                 | provider_access_token       | text                        | YES         | null                                                     |
| auth         | flow_state                 | provider_refresh_token      | text                        | YES         | null                                                     |
| auth         | flow_state                 | created_at                  | timestamp with time zone    | YES         | null                                                     |
| auth         | flow_state                 | updated_at                  | timestamp with time zone    | YES         | null                                                     |
| auth         | flow_state                 | authentication_method       | text                        | NO          | null                                                     |
| auth         | flow_state                 | auth_code_issued_at         | timestamp with time zone    | YES         | null                                                     |
| auth         | identities                 | provider_id                 | text                        | NO          | null                                                     |
| auth         | identities                 | user_id                     | uuid                        | NO          | null                                                     |
| auth         | identities                 | identity_data               | jsonb                       | NO          | null                                                     |
| auth         | identities                 | provider                    | text                        | NO          | null                                                     |
| auth         | identities                 | last_sign_in_at             | timestamp with time zone    | YES         | null                                                     |
| auth         | identities                 | created_at                  | timestamp with time zone    | YES         | null                                                     |
| auth         | identities                 | updated_at                  | timestamp with time zone    | YES         | null                                                     |
| auth         | identities                 | email                       | text                        | YES         | null                                                     |
| auth         | identities                 | id                          | uuid                        | NO          | gen_random_uuid()                                        |
| auth         | instances                  | id                          | uuid                        | NO          | null                                                     |
| auth         | instances                  | uuid                        | uuid                        | YES         | null                                                     |
| auth         | instances                  | raw_base_config             | text                        | YES         | null                                                     |
| auth         | instances                  | created_at                  | timestamp with time zone    | YES         | null                                                     |
| auth         | instances                  | updated_at                  | timestamp with time zone    | YES         | null                                                     |
| auth         | mfa_amr_claims             | session_id                  | uuid                        | NO          | null                                                     |
| auth         | mfa_amr_claims             | created_at                  | timestamp with time zone    | NO          | null                                                     |
| auth         | mfa_amr_claims             | updated_at                  | timestamp with time zone    | NO          | null                                                     |
| auth         | mfa_amr_claims             | authentication_method       | text                        | NO          | null                                                     |
| auth         | mfa_amr_claims             | id                          | uuid                        | NO          | null                                                     |
| auth         | mfa_challenges             | id                          | uuid                        | NO          | null                                                     |
| auth         | mfa_challenges             | factor_id                   | uuid                        | NO          | null                                                     |
| auth         | mfa_challenges             | created_at                  | timestamp with time zone    | NO          | null                                                     |
| auth         | mfa_challenges             | verified_at                 | timestamp with time zone    | YES         | null                                                     |
| auth         | mfa_challenges             | ip_address                  | inet                        | NO          | null                                                     |
| auth         | mfa_challenges             | otp_code                    | text                        | YES         | null                                                     |
| auth         | mfa_challenges             | web_authn_session_data      | jsonb                       | YES         | null                                                     |
| auth         | mfa_factors                | id                          | uuid                        | NO          | null                                                     |
| auth         | mfa_factors                | user_id                     | uuid                        | NO          | null                                                     |
| auth         | mfa_factors                | friendly_name               | text                        | YES         | null                                                     |
| auth         | mfa_factors                | factor_type                 | USER-DEFINED                | NO          | null                                                     |
| auth         | mfa_factors                | status                      | USER-DEFINED                | NO          | null                                                     |
| auth         | mfa_factors                | created_at                  | timestamp with time zone    | NO          | null                                                     |
| auth         | mfa_factors                | updated_at                  | timestamp with time zone    | NO          | null                                                     |
| auth         | mfa_factors                | secret                      | text                        | YES         | null                                                     |
| auth         | mfa_factors                | phone                       | text                        | YES         | null                                                     |
| auth         | mfa_factors                | last_challenged_at          | timestamp with time zone    | YES         | null                                                     |
| auth         | mfa_factors                | web_authn_credential        | jsonb                       | YES         | null                                                     |
| auth         | mfa_factors                | web_authn_aaguid            | uuid                        | YES         | null                                                     |
| auth         | one_time_tokens            | id                          | uuid                        | NO          | null                                                     |
| auth         | one_time_tokens            | user_id                     | uuid                        | NO          | null                                                     |
| auth         | one_time_tokens            | token_type                  | USER-DEFINED                | NO          | null                                                     |
| auth         | one_time_tokens            | token_hash                  | text                        | NO          | null                                                     |
| auth         | one_time_tokens            | relates_to                  | text                        | NO          | null                                                     |
| auth         | one_time_tokens            | created_at                  | timestamp without time zone | NO          | now()                                                    |
| auth         | one_time_tokens            | updated_at                  | timestamp without time zone | NO          | now()                                                    |
| auth         | refresh_tokens             | instance_id                 | uuid                        | YES         | null                                                     |
| auth         | refresh_tokens             | id                          | bigint                      | NO          | nextval('auth.refresh_tokens_id_seq'::regclass)          |
| auth         | refresh_tokens             | token                       | character varying           | YES         | null                                                     |
| auth         | refresh_tokens             | user_id                     | character varying           | YES         | null                                                     |
| auth         | refresh_tokens             | revoked                     | boolean                     | YES         | null                                                     |
| auth         | refresh_tokens             | created_at                  | timestamp with time zone    | YES         | null                                                     |
| auth         | refresh_tokens             | updated_at                  | timestamp with time zone    | YES         | null                                                     |
| auth         | refresh_tokens             | parent                      | character varying           | YES         | null                                                     |
| auth         | refresh_tokens             | session_id                  | uuid                        | YES         | null                                                     |
| auth         | saml_providers             | id                          | uuid                        | NO          | null                                                     |
| auth         | saml_providers             | sso_provider_id             | uuid                        | NO          | null                                                     |
| auth         | saml_providers             | entity_id                   | text                        | NO          | null                                                     |
| auth         | saml_providers             | metadata_xml                | text                        | NO          | null                                                     |
| auth         | saml_providers             | metadata_url                | text                        | YES         | null                                                     |
| auth         | saml_providers             | attribute_mapping           | jsonb                       | YES         | null                                                     |
| auth         | saml_providers             | created_at                  | timestamp with time zone    | YES         | null                                                     |
| auth         | saml_providers             | updated_at                  | timestamp with time zone    | YES         | null                                                     |
| auth         | saml_providers             | name_id_format              | text                        | YES         | null                                                     |
| auth         | saml_relay_states          | id                          | uuid                        | NO          | null                                                     |
| auth         | saml_relay_states          | sso_provider_id             | uuid                        | NO          | null                                                     |
| auth         | saml_relay_states          | request_id                  | text                        | NO          | null                                                     |
| auth         | saml_relay_states          | for_email                   | text                        | YES         | null                                                     |
| auth         | saml_relay_states          | redirect_to                 | text                        | YES         | null                                                     |
| auth         | saml_relay_states          | created_at                  | timestamp with time zone    | YES         | null                                                     |
| auth         | saml_relay_states          | updated_at                  | timestamp with time zone    | YES         | null                                                     |
| auth         | saml_relay_states          | flow_state_id               | uuid                        | YES         | null                                                     |
| auth         | schema_migrations          | version                     | character varying           | NO          | null                                                     |
| auth         | sessions                   | id                          | uuid                        | NO          | null                                                     |
| auth         | sessions                   | user_id                     | uuid                        | NO          | null                                                     |
| auth         | sessions                   | created_at                  | timestamp with time zone    | YES         | null                                                     |
| auth         | sessions                   | updated_at                  | timestamp with time zone    | YES         | null                                                     |
| auth         | sessions                   | factor_id                   | uuid                        | YES         | null                                                     |
| auth         | sessions                   | aal                         | USER-DEFINED                | YES         | null                                                     |
| auth         | sessions                   | not_after                   | timestamp with time zone    | YES         | null                                                     |
| auth         | sessions                   | refreshed_at                | timestamp without time zone | YES         | null                                                     |
| auth         | sessions                   | user_agent                  | text                        | YES         | null                                                     |
| auth         | sessions                   | ip                          | inet                        | YES         | null                                                     |
| auth         | sessions                   | tag                         | text                        | YES         | null                                                     |
| auth         | sso_domains                | id                          | uuid                        | NO          | null                                                     |
| auth         | sso_domains                | sso_provider_id             | uuid                        | NO          | null                                                     |
| auth         | sso_domains                | domain                      | text                        | NO          | null                                                     |
| auth         | sso_domains                | created_at                  | timestamp with time zone    | YES         | null                                                     |
| auth         | sso_domains                | updated_at                  | timestamp with time zone    | YES         | null                                                     |
| auth         | sso_providers              | id                          | uuid                        | NO          | null                                                     |
| auth         | sso_providers              | resource_id                 | text                        | YES         | null                                                     |
| auth         | sso_providers              | created_at                  | timestamp with time zone    | YES         | null                                                     |
| auth         | sso_providers              | updated_at                  | timestamp with time zone    | YES         | null                                                     |
| auth         | sso_providers              | disabled                    | boolean                     | YES         | null                                                     |
| auth         | users                      | instance_id                 | uuid                        | YES         | null                                                     |
| auth         | users                      | id                          | uuid                        | NO          | null                                                     |
| auth         | users                      | aud                         | character varying           | YES         | null                                                     |
| auth         | users                      | role                        | character varying           | YES         | null                                                     |
| auth         | users                      | email                       | character varying           | YES         | null                                                     |
| auth         | users                      | encrypted_password          | character varying           | YES         | null                                                     |
| auth         | users                      | email_confirmed_at          | timestamp with time zone    | YES         | null                                                     |
| auth         | users                      | invited_at                  | timestamp with time zone    | YES         | null                                                     |
| auth         | users                      | confirmation_token          | character varying           | YES         | null                                                     |
| auth         | users                      | confirmation_sent_at        | timestamp with time zone    | YES         | null                                                     |
| auth         | users                      | recovery_token              | character varying           | YES         | null                                                     |
| auth         | users                      | recovery_sent_at            | timestamp with time zone    | YES         | null                                                     |
| auth         | users                      | email_change_token_new      | character varying           | YES         | null                                                     |
| auth         | users                      | email_change                | character varying           | YES         | null                                                     |
| auth         | users                      | email_change_sent_at        | timestamp with time zone    | YES         | null                                                     |
| auth         | users                      | last_sign_in_at             | timestamp with time zone    | YES         | null                                                     |
| auth         | users                      | raw_app_meta_data           | jsonb                       | YES         | null                                                     |
| auth         | users                      | raw_user_meta_data          | jsonb                       | YES         | null                                                     |
| auth         | users                      | is_super_admin              | boolean                     | YES         | null                                                     |
| auth         | users                      | created_at                  | timestamp with time zone    | YES         | null                                                     |
| auth         | users                      | updated_at                  | timestamp with time zone    | YES         | null                                                     |
| auth         | users                      | phone                       | text                        | YES         | NULL::character varying                                  |
| auth         | users                      | phone_confirmed_at          | timestamp with time zone    | YES         | null                                                     |
| auth         | users                      | phone_change                | text                        | YES         | ''::character varying                                    |
| auth         | users                      | phone_change_token          | character varying           | YES         | ''::character varying                                    |
| auth         | users                      | phone_change_sent_at        | timestamp with time zone    | YES         | null                                                     |
| auth         | users                      | confirmed_at                | timestamp with time zone    | YES         | null                                                     |
| auth         | users                      | email_change_token_current  | character varying           | YES         | ''::character varying                                    |
| auth         | users                      | email_change_confirm_status | smallint                    | YES         | 0                                                        |
| auth         | users                      | banned_until                | timestamp with time zone    | YES         | null                                                     |
| auth         | users                      | reauthentication_token      | character varying           | YES         | ''::character varying                                    |
| auth         | users                      | reauthentication_sent_at    | timestamp with time zone    | YES         | null                                                     |
| auth         | users                      | is_sso_user                 | boolean                     | NO          | false                                                    |
| auth         | users                      | deleted_at                  | timestamp with time zone    | YES         | null                                                     |
| auth         | users                      | is_anonymous                | boolean                     | NO          | false                                                    |
| extensions   | pg_stat_statements         | userid                      | oid                         | YES         | null                                                     |
| extensions   | pg_stat_statements         | dbid                        | oid                         | YES         | null                                                     |
| extensions   | pg_stat_statements         | toplevel                    | boolean                     | YES         | null                                                     |
| extensions   | pg_stat_statements         | queryid                     | bigint                      | YES         | null                                                     |
| extensions   | pg_stat_statements         | query                       | text                        | YES         | null                                                     |
| extensions   | pg_stat_statements         | plans                       | bigint                      | YES         | null                                                     |
| extensions   | pg_stat_statements         | total_plan_time             | double precision            | YES         | null                                                     |
| extensions   | pg_stat_statements         | min_plan_time               | double precision            | YES         | null                                                     |
| extensions   | pg_stat_statements         | max_plan_time               | double precision            | YES         | null                                                     |
| extensions   | pg_stat_statements         | mean_plan_time              | double precision            | YES         | null                                                     |
| extensions   | pg_stat_statements         | stddev_plan_time            | double precision            | YES         | null                                                     |
| extensions   | pg_stat_statements         | calls                       | bigint                      | YES         | null                                                     |
| extensions   | pg_stat_statements         | total_exec_time             | double precision            | YES         | null                                                     |
| extensions   | pg_stat_statements         | min_exec_time               | double precision            | YES         | null                                                     |
| extensions   | pg_stat_statements         | max_exec_time               | double precision            | YES         | null                                                     |
| extensions   | pg_stat_statements         | mean_exec_time              | double precision            | YES         | null                                                     |
| extensions   | pg_stat_statements         | stddev_exec_time            | double precision            | YES         | null                                                     |
| extensions   | pg_stat_statements         | rows                        | bigint                      | YES         | null                                                     |
| extensions   | pg_stat_statements         | shared_blks_hit             | bigint                      | YES         | null                                                     |
| extensions   | pg_stat_statements         | shared_blks_read            | bigint                      | YES         | null                                                     |
| extensions   | pg_stat_statements         | shared_blks_dirtied         | bigint                      | YES         | null                                                     |
| extensions   | pg_stat_statements         | shared_blks_written         | bigint                      | YES         | null                                                     |
| extensions   | pg_stat_statements         | local_blks_hit              | bigint                      | YES         | null                                                     |
| extensions   | pg_stat_statements         | local_blks_read             | bigint                      | YES         | null                                                     |
| extensions   | pg_stat_statements         | local_blks_dirtied          | bigint                      | YES         | null                                                     |
| extensions   | pg_stat_statements         | local_blks_written          | bigint                      | YES         | null                                                     |
| extensions   | pg_stat_statements         | temp_blks_read              | bigint                      | YES         | null                                                     |
| extensions   | pg_stat_statements         | temp_blks_written           | bigint                      | YES         | null                                                     |
| extensions   | pg_stat_statements         | blk_read_time               | double precision            | YES         | null                                                     |
| extensions   | pg_stat_statements         | blk_write_time              | double precision            | YES         | null                                                     |
| extensions   | pg_stat_statements         | temp_blk_read_time          | double precision            | YES         | null                                                     |
| extensions   | pg_stat_statements         | temp_blk_write_time         | double precision            | YES         | null                                                     |
| extensions   | pg_stat_statements         | wal_records                 | bigint                      | YES         | null                                                     |
| extensions   | pg_stat_statements         | wal_fpi                     | bigint                      | YES         | null                                                     |
| extensions   | pg_stat_statements         | wal_bytes                   | numeric                     | YES         | null                                                     |
| extensions   | pg_stat_statements         | jit_functions               | bigint                      | YES         | null                                                     |
| extensions   | pg_stat_statements         | jit_generation_time         | double precision            | YES         | null                                                     |
| extensions   | pg_stat_statements         | jit_inlining_count          | bigint                      | YES         | null                                                     |
| extensions   | pg_stat_statements         | jit_inlining_time           | double precision            | YES         | null                                                     |
| extensions   | pg_stat_statements         | jit_optimization_count      | bigint                      | YES         | null                                                     |
| extensions   | pg_stat_statements         | jit_optimization_time       | double precision            | YES         | null                                                     |
| extensions   | pg_stat_statements         | jit_emission_count          | bigint                      | YES         | null                                                     |
| extensions   | pg_stat_statements         | jit_emission_time           | double precision            | YES         | null                                                     |
| extensions   | pg_stat_statements_info    | dealloc                     | bigint                      | YES         | null                                                     |
| extensions   | pg_stat_statements_info    | stats_reset                 | timestamp with time zone    | YES         | null                                                     |
| net          | _http_response             | id                          | bigint                      | YES         | null                                                     |
| net          | _http_response             | status_code                 | integer                     | YES         | null                                                     |
| net          | _http_response             | content_type                | text                        | YES         | null                                                     |
| net          | _http_response             | headers                     | jsonb                       | YES         | null                                                     |
| net          | _http_response             | content                     | text                        | YES         | null                                                     |
| net          | _http_response             | timed_out                   | boolean                     | YES         | null                                                     |
| net          | _http_response             | error_msg                   | text                        | YES         | null                                                     |
| net          | _http_response             | created                     | timestamp with time zone    | NO          | now()                                                    |
| net          | http_request_queue         | id                          | bigint                      | NO          | nextval('net.http_request_queue_id_seq'::regclass)       |
| net          | http_request_queue         | method                      | text                        | NO          | null                                                     |
| net          | http_request_queue         | url                         | text                        | NO          | null                                                     |
| net          | http_request_queue         | headers                     | jsonb                       | NO          | null                                                     |
| net          | http_request_queue         | body                        | bytea                       | YES         | null                                                     |
| net          | http_request_queue         | timeout_milliseconds        | integer                     | NO          | null                                                     |
| pgsodium     | decrypted_key              | id                          | uuid                        | YES         | null                                                     |
| pgsodium     | decrypted_key              | status                      | USER-DEFINED                | YES         | null                                                     |
| pgsodium     | decrypted_key              | created                     | timestamp with time zone    | YES         | null                                                     |
| pgsodium     | decrypted_key              | expires                     | timestamp with time zone    | YES         | null                                                     |
| pgsodium     | decrypted_key              | key_type                    | USER-DEFINED                | YES         | null                                                     |
| pgsodium     | decrypted_key              | key_id                      | bigint                      | YES         | null                                                     |
| pgsodium     | decrypted_key              | key_context                 | bytea                       | YES         | null                                                     |
| pgsodium     | decrypted_key              | name                        | text                        | YES         | null                                                     |
| pgsodium     | decrypted_key              | associated_data             | text                        | YES         | null                                                     |
| pgsodium     | decrypted_key              | raw_key                     | bytea                       | YES         | null                                                     |
| pgsodium     | decrypted_key              | decrypted_raw_key           | bytea                       | YES         | null                                                     |
| pgsodium     | decrypted_key              | raw_key_nonce               | bytea                       | YES         | null                                                     |
| pgsodium     | decrypted_key              | parent_key                  | uuid                        | YES         | null                                                     |
| pgsodium     | decrypted_key              | comment                     | text                        | YES         | null                                                     |
| pgsodium     | key                        | id                          | uuid                        | NO          | gen_random_uuid()                                        |
| pgsodium     | key                        | status                      | USER-DEFINED                | YES         | 'valid'::pgsodium.key_status                             |
| pgsodium     | key                        | created                     | timestamp with time zone    | NO          | CURRENT_TIMESTAMP                                        |
| pgsodium     | key                        | expires                     | timestamp with time zone    | YES         | null                                                     |
| pgsodium     | key                        | key_type                    | USER-DEFINED                | YES         | null                                                     |
| pgsodium     | key                        | key_id                      | bigint                      | YES         | nextval('pgsodium.key_key_id_seq'::regclass)             |
| pgsodium     | key                        | key_context                 | bytea                       | YES         | '\x7067736f6469756d'::bytea                              |
| pgsodium     | key                        | name                        | text                        | YES         | null                                                     |
| pgsodium     | key                        | associated_data             | text                        | YES         | 'associated'::text                                       |
| pgsodium     | key                        | raw_key                     | bytea                       | YES         | null                                                     |
| pgsodium     | key                        | raw_key_nonce               | bytea                       | YES         | null                                                     |
| pgsodium     | key                        | parent_key                  | uuid                        | YES         | null                                                     |
| pgsodium     | key                        | comment                     | text                        | YES         | null                                                     |
| pgsodium     | key                        | user_data                   | text                        | YES         | null                                                     |
| pgsodium     | mask_columns               | attname                     | name                        | YES         | null                                                     |
| pgsodium     | mask_columns               | attrelid                    | oid                         | YES         | null                                                     |
| pgsodium     | mask_columns               | key_id                      | text                        | YES         | null                                                     |
| pgsodium     | mask_columns               | key_id_column               | text                        | YES         | null                                                     |
| pgsodium     | mask_columns               | associated_columns          | text                        | YES         | null                                                     |
| pgsodium     | mask_columns               | nonce_column                | text                        | YES         | null                                                     |
| pgsodium     | mask_columns               | format_type                 | text                        | YES         | null                                                     |
| pgsodium     | masking_rule               | attrelid                    | oid                         | YES         | null                                                     |
| pgsodium     | masking_rule               | attnum                      | integer                     | YES         | null                                                     |
| pgsodium     | masking_rule               | relnamespace                | regnamespace                | YES         | null                                                     |
| pgsodium     | masking_rule               | relname                     | name                        | YES         | null                                                     |
| pgsodium     | masking_rule               | attname                     | name                        | YES         | null                                                     |
| pgsodium     | masking_rule               | format_type                 | text                        | YES         | null                                                     |
| pgsodium     | masking_rule               | col_description             | text                        | YES         | null                                                     |
| pgsodium     | masking_rule               | key_id_column               | text                        | YES         | null                                                     |
| pgsodium     | masking_rule               | key_id                      | text                        | YES         | null                                                     |
| pgsodium     | masking_rule               | associated_columns          | text                        | YES         | null                                                     |
| pgsodium     | masking_rule               | nonce_column                | text                        | YES         | null                                                     |
| pgsodium     | masking_rule               | view_name                   | text                        | YES         | null                                                     |
| pgsodium     | masking_rule               | priority                    | integer                     | YES         | null                                                     |
| pgsodium     | masking_rule               | security_invoker            | boolean                     | YES         | null                                                     |
| pgsodium     | valid_key                  | id                          | uuid                        | YES         | null                                                     |
| pgsodium     | valid_key                  | name                        | text                        | YES         | null                                                     |
| pgsodium     | valid_key                  | status                      | USER-DEFINED                | YES         | null                                                     |
| pgsodium     | valid_key                  | key_type                    | USER-DEFINED                | YES         | null                                                     |
| pgsodium     | valid_key                  | key_id                      | bigint                      | YES         | null                                                     |
| pgsodium     | valid_key                  | key_context                 | bytea                       | YES         | null                                                     |
| pgsodium     | valid_key                  | created                     | timestamp with time zone    | YES         | null                                                     |
| pgsodium     | valid_key                  | expires                     | timestamp with time zone    | YES         | null                                                     |
| pgsodium     | valid_key                  | associated_data             | text                        | YES         | null                                                     |
| public       | account_book               | account_book_id             | bigint                      | NO          | nextval('account_book_account_book_id_seq'::regclass)    |
| public       | account_book               | entity_type                 | character varying           | NO          | null                                                     |
| public       | account_book               | entity_id                   | bigint                      | NO          | null                                                     |
| public       | account_book               | entity_name                 | character varying           | NO          | null                                                     |
| public       | account_book               | transaction_type            | character varying           | NO          | null                                                     |
| public       | account_book               | amount                      | numeric                     | NO          | null                                                     |
| public       | account_book               | description                 | text                        | NO          | null                                                     |
| public       | account_book               | reference                   | character varying           | YES         | null                                                     |
| public       | account_book               | transaction_date            | date                        | NO          | null                                                     |
| public       | account_book               | created_at                  | timestamp with time zone    | YES         | CURRENT_TIMESTAMP                                        |
| public       | account_book               | updated_at                  | timestamp with time zone    | YES         | CURRENT_TIMESTAMP                                        |
| public       | account_book_summary       | entity_type                 | character varying           | YES         | null                                                     |
| public       | account_book_summary       | transaction_type            | character varying           | YES         | null                                                     |
| public       | account_book_summary       | transaction_count           | bigint                      | YES         | null                                                     |
| public       | account_book_summary       | total_amount                | numeric                     | YES         | null                                                     |
| public       | account_book_summary       | average_amount              | numeric                     | YES         | null                                                     |
| public       | account_book_summary       | min_amount                  | numeric                     | YES         | null                                                     |
| public       | account_book_summary       | max_amount                  | numeric                     | YES         | null                                                     |
| public       | account_book_summary       | earliest_transaction        | date                        | YES         | null                                                     |
| public       | account_book_summary       | latest_transaction          | date                        | YES         | null                                                     |
| public       | addresses                  | address_id                  | integer                     | NO          | null                                                     |
| public       | addresses                  | shipping_address            | text                        | YES         | ''::text                                                 |
| public       | addresses                  | phone_number                | text                        | YES         | ''::text                                                 |
| public       | addresses                  | postal_code                 | text                        | YES         | ''::text                                                 |
| public       | addresses                  | city                        | text                        | YES         | ''::text                                                 |
| public       | addresses                  | country                     | text                        | YES         | ''::text                                                 |
| public       | addresses                  | full_name                   | text                        | NO          | null                                                     |
| public       | addresses                  | customer_id                 | integer                     | YES         | null                                                     |
| public       | addresses                  | vendor_id                   | integer                     | YES         | null                                                     |
| public       | addresses                  | salesman_id                 | integer                     | YES         | null                                                     |
| public       | addresses                  | user_id                     | integer                     | YES         | null                                                     |
| public       | app_versions               | id                          | bigint                      | NO          | nextval('app_versions_id_seq'::regclass)                 |
| public       | app_versions               | version                     | text                        | NO          | null                                                     |
| public       | app_versions               | force_update                | boolean                     | NO          | false                                                    |
| public       | app_versions               | redirect_url                | text                        | NO          | null                                                     |
| public       | app_versions               | description                 | text                        | YES         | null                                                     |
| public       | app_versions               | created_at                  | timestamp with time zone    | YES         | now()                                                    |
| public       | app_versions               | app_locked                  | boolean                     | NO          | false                                                    |
| public       | brands                     | brandname                   | text                        | YES         | null                                                     |
| public       | brands                     | isVerified                  | boolean                     | YES         | false                                                    |
| public       | brands                     | isFeatured                  | boolean                     | YES         | null                                                     |
| public       | brands                     | brandID                     | integer                     | NO          | null                                                     |
| public       | brands                     | product_count               | bigint                      | NO          | '0'::bigint                                              |
| public       | cart                       | cart_id                     | integer                     | NO          | null                                                     |
| public       | cart                       | variant_id                  | integer                     | YES         | null                                                     |
| public       | cart                       | quantity                    | text                        | NO          | ''::text                                                 |
| public       | cart                       | customer_id                 | integer                     | YES         | null                                                     |
| public       | categories                 | category_id                 | integer                     | NO          | null                                                     |
| public       | categories                 | category_name               | text                        | NO          | null                                                     |
| public       | categories                 | isFeatured                  | boolean                     | YES         | false                                                    |
| public       | categories                 | created_at                  | timestamp with time zone    | YES         | now()                                                    |
| public       | categories                 | product_count               | integer                     | YES         | null                                                     |
| public       | customer_public_info       | customer_id                 | integer                     | YES         | null                                                     |
| public       | customer_public_info       | first_name                  | text                        | YES         | null                                                     |
| public       | customer_public_info       | last_name                   | text                        | YES         | null                                                     |
| public       | customers                  | customer_id                 | integer                     | NO          | null                                                     |
| public       | customers                  | phone_number                | text                        | YES         | ''::text                                                 |
| public       | customers                  | first_name                  | text                        | NO          | ''::text                                                 |
| public       | customers                  | last_name                   | text                        | YES         | ''::text                                                 |
| public       | customers                  | cnic                        | text                        | YES         | ''::text                                                 |
| public       | customers                  | email                       | text                        | NO          | ''::text                                                 |
| public       | customers                  | created_at                  | timestamp with time zone    | YES         | now()                                                    |
| public       | customers                  | dob                         | timestamp with time zone    | YES         | null                                                     |
| public       | customers                  | gender                      | USER-DEFINED                | YES         | null                                                     |
| public       | customers                  | auth_uid                    | uuid                        | YES         | auth.uid()                                               |
| public       | customers                  | fcm_token                   | text                        | YES         | null                                                     |
| public       | expenses                   | expense_id                  | integer                     | NO          | null                                                     |
| public       | expenses                   | description                 | text                        | NO          | null                                                     |
| public       | expenses                   | amount                      | numeric                     | YES         | 0.0                                                      |
| public       | expenses                   | created_at                  | timestamp with time zone    | NO          | now()                                                    |
| public       | extras                     | extraId                     | bigint                      | NO          | null                                                     |
| public       | extras                     | AdminKey                    | text                        | YES         | null                                                     |
| public       | guarantors                 | first_name                  | text                        | NO          | ''::text                                                 |
| public       | guarantors                 | address                     | text                        | YES         | null                                                     |
| public       | guarantors                 | pfp                         | text                        | YES         | null                                                     |
| public       | guarantors                 | cnic                        | text                        | NO          | ''::text                                                 |
| public       | guarantors                 | email                       | text                        | NO          | ''::text                                                 |
| public       | guarantors                 | phone_number                | text                        | YES         | ''::text                                                 |
| public       | guarantors                 | last_name                   | text                        | YES         | ''::text                                                 |
| public       | guarantors                 | guarantor_id                | integer                     | NO          | null                                                     |
| public       | image_entity               | image_entity_id             | integer                     | NO          | null                                                     |
| public       | image_entity               | image_id                    | integer                     | YES         | null                                                     |
| public       | image_entity               | entity_id                   | integer                     | YES         | null                                                     |
| public       | image_entity               | entity_category             | text                        | YES         | null                                                     |
| public       | image_entity               | created_at                  | timestamp with time zone    | NO          | now()                                                    |
| public       | image_entity               | isFeatured                  | boolean                     | YES         | false                                                    |
| public       | images                     | filename                    | text                        | YES         | null                                                     |
| public       | images                     | created_at                  | timestamp with time zone    | YES         | now()                                                    |
| public       | images                     | image_url                   | text                        | YES         | null                                                     |
| public       | images                     | image_id                    | integer                     | NO          | null                                                     |
| public       | images                     | folderType                  | text                        | YES         | null                                                     |
| public       | installment_payments       | paid_date                   | timestamp with time zone    | YES         | null                                                     |
| public       | installment_payments       | paid_amount                 | text                        | YES         | null                                                     |
| public       | installment_payments       | status                      | text                        | YES         | null                                                     |
| public       | installment_payments       | sequence_no                 | integer                     | NO          | null                                                     |
| public       | installment_payments       | installment_plan_id         | integer                     | NO          | null                                                     |
| public       | installment_payments       | due_date                    | timestamp with time zone    | NO          | null                                                     |
| public       | installment_payments       | is_paid                     | boolean                     | YES         | false                                                    |
| public       | installment_payments       | created_at                  | timestamp without time zone | YES         | now()                                                    |
| public       | installment_payments       | amount_due                  | text                        | NO          | null                                                     |
| public       | installment_plans          | guarantor1_id               | integer                     | YES         | null                                                     |
| public       | installment_plans          | installment_plans_id        | integer                     | NO          | null                                                     |
| public       | installment_plans          | order_id                    | integer                     | NO          | null                                                     |
| public       | installment_plans          | created_at                  | timestamp with time zone    | YES         | now()                                                    |
| public       | installment_plans          | first_installment_date      | timestamp with time zone    | YES         | null                                                     |
| public       | installment_plans          | guarantor2_id               | integer                     | YES         | null                                                     |
| public       | installment_plans          | total_amount                | text                        | NO          | null                                                     |
| public       | installment_plans          | down_payment                | text                        | NO          | null                                                     |
| public       | installment_plans          | number_of_installments      | text                        | NO          | null                                                     |
| public       | installment_plans          | document_charges            | text                        | YES         | null                                                     |
| public       | installment_plans          | margin                      | text                        | YES         | null                                                     |
| public       | installment_plans          | frequency_in_month          | text                        | YES         | null                                                     |
| public       | installment_plans          | other_charges               | text                        | YES         | null                                                     |
| public       | installment_plans          | duration                    | text                        | YES         | null                                                     |
| public       | installment_plans          | note                        | text                        | YES         | null                                                     |
| public       | installment_plans          | status                      | text                        | YES         | 'active'::text                                           |
| public       | inventory_reservations     | reservation_id              | character varying           | NO          | null                                                     |
| public       | inventory_reservations     | variant_id                  | integer                     | NO          | null                                                     |
| public       | inventory_reservations     | quantity                    | integer                     | NO          | null                                                     |
| public       | inventory_reservations     | expires_at                  | timestamp with time zone    | NO          | null                                                     |
| public       | inventory_reservations     | created_at                  | timestamp with time zone    | YES         | now()                                                    |
| public       | inventory_status           | variant_id                  | integer                     | YES         | null                                                     |
| public       | inventory_status           | product_name                | text                        | YES         | null                                                     |
| public       | inventory_status           | variant_name                | text                        | YES         | null                                                     |
| public       | inventory_status           | total_stock                 | integer                     | YES         | null                                                     |
| public       | inventory_status           | reserved_quantity           | bigint                      | YES         | null                                                     |
| public       | inventory_status           | available_stock             | bigint                      | YES         | null                                                     |
| public       | inventory_status           | sell_price                  | numeric                     | YES         | null                                                     |
| public       | invoice_coupons            | coupon_id                   | integer                     | NO          | nextval('invoice_coupons_id_seq'::regclass)              |
| public       | invoice_coupons            | title                       | text                        | NO          | null                                                     |
| public       | invoice_coupons            | coupon_code                 | text                        | NO          | null                                                     |
| public       | invoice_coupons            | discount_type               | text                        | NO          | null                                                     |
| public       | invoice_coupons            | amount                      | numeric                     | NO          | null                                                     |
| public       | invoice_coupons            | usage_limit                 | integer                     | YES         | null                                                     |
| public       | invoice_coupons            | used_count                  | integer                     | NO          | 0                                                        |
| public       | invoice_coupons            | start_date                  | timestamp with time zone    | NO          | null                                                     |
| public       | invoice_coupons            | end_date                    | timestamp with time zone    | NO          | null                                                     |
| public       | invoice_coupons            | is_active                   | boolean                     | NO          | true                                                     |
| public       | invoice_coupons            | created_at                  | timestamp with time zone    | NO          | now()                                                    |
| public       | kiosk_cart                 | kiosk_id                    | integer                     | NO          | nextval('kiosk_cart_id_seq'::regclass)                   |
| public       | kiosk_cart                 | kiosk_session_id            | uuid                        | NO          | null                                                     |
| public       | kiosk_cart                 | variant_id                  | integer                     | NO          | null                                                     |
| public       | kiosk_cart                 | quantity                    | integer                     | NO          | null                                                     |
| public       | kiosk_cart                 | created_at                  | timestamp without time zone | YES         | now()                                                    |
| public       | monthly_account_summary    | month                       | timestamp with time zone    | YES         | null                                                     |
| public       | monthly_account_summary    | entity_type                 | character varying           | YES         | null                                                     |
| public       | monthly_account_summary    | transaction_type            | character varying           | YES         | null                                                     |
| public       | monthly_account_summary    | transaction_count           | bigint                      | YES         | null                                                     |
| public       | monthly_account_summary    | total_amount                | numeric                     | YES         | null                                                     |
| public       | notifications              | notification_id             | integer                     | NO          | null                                                     |
| public       | notifications              | created_at                  | timestamp with time zone    | NO          | (now() AT TIME ZONE 'utc'::text)                         |
| public       | notifications              | description                 | text                        | YES         | null                                                     |
| public       | notifications              | sub_description             | text                        | YES         | null                                                     |
| public       | notifications              | isRead                      | boolean                     | YES         | false                                                    |
| public       | notifications              | NotificationType            | text                        | YES         | null                                                     |
| public       | notifications              | expires_at                  | timestamp with time zone    | YES         | (now() + '10 days'::interval)                            |
| public       | notifications              | order_id                    | integer                     | YES         | null                                                     |
| public       | notifications              | installment_plan_id         | integer                     | YES         | null                                                     |
| public       | notifications              | product_id                  | integer                     | YES         | null                                                     |
| public       | order_addresses            | order_address_id            | integer                     | NO          | null                                                     |
| public       | order_addresses            | shipping_address            | text                        | YES         | ''::text                                                 |
| public       | order_addresses            | phone_number                | text                        | YES         | ''::text                                                 |
| public       | order_addresses            | postal_code                 | text                        | YES         | ''::text                                                 |
| public       | order_addresses            | city                        | text                        | YES         | ''::text                                                 |
| public       | order_addresses            | country                     | text                        | YES         | ''::text                                                 |
| public       | order_addresses            | full_name                   | text                        | NO          | null                                                     |
| public       | order_addresses            | customer_id                 | integer                     | YES         | null                                                     |
| public       | order_addresses            | vendor_id                   | integer                     | YES         | null                                                     |
| public       | order_addresses            | salesman_id                 | integer                     | YES         | null                                                     |
| public       | order_addresses            | user_id                     | integer                     | YES         | null                                                     |
| public       | order_addresses            | address_id                  | integer                     | YES         | null                                                     |
| public       | order_items                | product_id                  | integer                     | NO          | null                                                     |
| public       | order_items                | price                       | numeric                     | NO          | null                                                     |
| public       | order_items                | quantity                    | integer                     | NO          | null                                                     |
| public       | order_items                | order_id                    | integer                     | NO          | null                                                     |
| public       | order_items                | unit                        | character varying           | YES         | null                                                     |
| public       | order_items                | total_buy_price             | numeric                     | YES         | 0.0                                                      |
| public       | order_items                | created_at                  | timestamp with time zone    | YES         | (now() AT TIME ZONE 'utc'::text)                         |
| public       | order_items                | variant_id                  | integer                     | NO          | null                                                     |
| public       | orders                     | order_id                    | integer                     | NO          | nextval('orders_order_id_seq'::regclass)                 |
| public       | orders                     | order_date                  | date                        | NO          | null                                                     |
| public       | orders                     | sub_total                   | numeric                     | NO          | null                                                     |
| public       | orders                     | status                      | text                        | NO          | null                                                     |
| public       | orders                     | saletype                    | text                        | YES         | null                                                     |
| public       | orders                     | address_id                  | integer                     | YES         | null                                                     |
| public       | orders                     | paid_amount                 | numeric                     | YES         | null                                                     |
| public       | orders                     | buying_price                | numeric                     | YES         | null                                                     |
| public       | orders                     | discount                    | numeric                     | YES         | 0.0                                                      |
| public       | orders                     | tax                         | numeric                     | YES         | 0.0                                                      |
| public       | orders                     | shipping_fee                | numeric                     | YES         | 0.0                                                      |
| public       | orders                     | user_id                     | integer                     | YES         | null                                                     |
| public       | orders                     | customer_id                 | integer                     | YES         | null                                                     |
| public       | orders                     | idempotency_key             | character varying           | YES         | null                                                     |
| public       | orders                     | payment_method              | character varying           | YES         | 'cod'::character varying                                 |
| public       | orders                     | salesman_id                 | integer                     | YES         | null                                                     |
| public       | orders                     | salesman_comission          | integer                     | YES         | null                                                     |
| public       | orders                     | shipping_method             | text                        | YES         | null                                                     |
| public       | product_discounts          | discount_id                 | integer                     | NO          | nextval('product_discounts_id_seq'::regclass)            |
| public       | product_discounts          | product_id                  | integer                     | NO          | null                                                     |
| public       | product_discounts          | discount_type               | text                        | NO          | null                                                     |
| public       | product_discounts          | amount                      | numeric                     | NO          | null                                                     |
| public       | product_discounts          | start_date                  | timestamp with time zone    | NO          | null                                                     |
| public       | product_discounts          | end_date                    | timestamp with time zone    | NO          | null                                                     |
| public       | product_discounts          | is_active                   | boolean                     | NO          | true                                                     |
| public       | product_discounts          | created_at                  | timestamp with time zone    | NO          | now()                                                    |
| public       | product_variants           | variant_id                  | integer                     | NO          | nextval('product_variants_variant_id_seq'::regclass)     |
| public       | product_variants           | product_id                  | integer                     | NO          | null                                                     |
| public       | product_variants           | buy_price                   | numeric                     | NO          | null                                                     |
| public       | product_variants           | sell_price                  | numeric                     | NO          | null                                                     |
| public       | product_variants           | created_at                  | timestamp with time zone    | YES         | now()                                                    |
| public       | product_variants           | updated_at                  | timestamp with time zone    | YES         | now()                                                    |
| public       | product_variants           | sku                         | character varying           | YES         | null                                                     |
| public       | product_variants           | variant_name                | text                        | NO          | null                                                     |
| public       | product_variants           | is_visible                  | boolean                     | YES         | true                                                     |
| public       | product_variants           | stock                       | integer                     | YES         | 0                                                        |
| public       | products                   | product_id                  | integer                     | NO          | nextval('products_product_id_seq'::regclass)             |
| public       | products                   | name                        | text                        | NO          | ''::text                                                 |
| public       | products                   | description                 | text                        | YES         | ''::text                                                 |
| public       | products                   | base_price                  | text                        | YES         | ''::text                                                 |
| public       | products                   | sale_price                  | text                        | YES         | ''::text                                                 |
| public       | products                   | category_id                 | integer                     | YES         | 11                                                       |
| public       | products                   | ispopular                   | boolean                     | YES         | false                                                    |
| public       | products                   | stock_quantity              | integer                     | YES         | 0                                                        |
| public       | products                   | created_at                  | timestamp with time zone    | YES         | CURRENT_TIMESTAMP                                        |
| public       | products                   | brandID                     | integer                     | YES         | 20                                                       |
| public       | products                   | alert_stock                 | integer                     | YES         | null                                                     |
| public       | products                   | isVisible                   | boolean                     | YES         | false                                                    |
| public       | products                   | tag                         | USER-DEFINED                | YES         | null                                                     |
| public       | products                   | price_range                 | text                        | YES         | '--'::text                                               |
| public       | purchase_items             | purchase_item_id            | bigint                      | NO          | nextval('purchase_items_purchase_item_id_seq'::regclass) |
| public       | purchase_items             | purchase_id                 | bigint                      | NO          | null                                                     |
| public       | purchase_items             | product_id                  | bigint                      | NO          | null                                                     |
| public       | purchase_items             | variant_id                  | bigint                      | YES         | null                                                     |
| public       | purchase_items             | price                       | numeric                     | NO          | null                                                     |
| public       | purchase_items             | quantity                    | integer                     | NO          | 1                                                        |
| public       | purchase_items             | unit                        | character varying           | YES         | null                                                     |
| public       | purchase_items             | created_at                  | timestamp with time zone    | YES         | CURRENT_TIMESTAMP                                        |
| public       | purchases                  | purchase_id                 | bigint                      | NO          | nextval('purchases_purchase_id_seq'::regclass)           |
| public       | purchases                  | purchase_date               | date                        | NO          | CURRENT_DATE                                             |
| public       | purchases                  | sub_total                   | numeric                     | NO          | 0.00                                                     |
| public       | purchases                  | status                      | character varying           | NO          | 'pending'::character varying                             |
| public       | purchases                  | address_id                  | bigint                      | YES         | null                                                     |
| public       | purchases                  | paid_amount                 | numeric                     | YES         | 0.00                                                     |
| public       | purchases                  | vendor_id                   | bigint                      | YES         | null                                                     |
| public       | purchases                  | discount                    | numeric                     | YES         | 0.00                                                     |
| public       | purchases                  | tax                         | numeric                     | YES         | 0.00                                                     |
| public       | purchases                  | shipping_fee                | numeric                     | YES         | 0.00                                                     |
| public       | purchases                  | created_at                  | timestamp with time zone    | YES         | CURRENT_TIMESTAMP                                        |
| public       | purchases                  | updated_at                  | timestamp with time zone    | YES         | CURRENT_TIMESTAMP                                        |
| public       | purchases                  | user_id                     | integer                     | YES         | null                                                     |
| public       | reviews                    | review_id                   | bigint                      | NO          | null                                                     |
| public       | reviews                    | product_id                  | integer                     | YES         | null                                                     |
| public       | reviews                    | sent_at                     | timestamp with time zone    | NO          | now()                                                    |
| public       | reviews                    | review                      | text                        | YES         | ''::text                                                 |
| public       | reviews                    | rating                      | numeric                     | YES         | null                                                     |
| public       | reviews                    | customer_id                 | integer                     | YES         | null                                                     |
| public       | salesman                   | phone_number                | text                        | YES         | ''::text                                                 |
| public       | salesman                   | email                       | text                        | NO          | ''::text                                                 |
| public       | salesman                   | last_name                   | text                        | YES         | ''::text                                                 |
| public       | salesman                   | cnic                        | text                        | NO          | ''::text                                                 |
| public       | salesman                   | city                        | text                        | NO          | ''::text                                                 |
| public       | salesman                   | first_name                  | text                        | NO          | ''::text                                                 |
| public       | salesman                   | salesman_id                 | integer                     | NO          | null                                                     |
| public       | salesman                   | area                        | text                        | NO          | ''::text                                                 |
| public       | salesman                   | pfp                         | text                        | YES         | null                                                     |
| public       | salesman                   | created_at                  | timestamp with time zone    | YES         | now()                                                    |
| public       | salesman                   | comission                   | integer                     | YES         | null                                                     |
| public       | security_audit_log         | log_id                      | integer                     | NO          | nextval('security_audit_log_log_id_seq'::regclass)       |
| public       | security_audit_log         | event_type                  | character varying           | NO          | null                                                     |
| public       | security_audit_log         | event_data                  | jsonb                       | YES         | null                                                     |
| public       | security_audit_log         | timestamp                   | timestamp with time zone    | YES         | now()                                                    |
| public       | security_audit_log         | ip_address                  | inet                        | YES         | null                                                     |
| public       | security_audit_log         | user_agent                  | text                        | YES         | null                                                     |
| public       | security_audit_log         | customer_id                 | integer                     | YES         | null                                                     |
| public       | security_audit_log         | severity                    | character varying           | YES         | 'info'::character varying                                |
| public       | security_dashboard         | date                        | date                        | YES         | null                                                     |
| public       | security_dashboard         | event_type                  | character varying           | YES         | null                                                     |
| public       | security_dashboard         | severity                    | character varying           | YES         | null                                                     |
| public       | security_dashboard         | event_count                 | bigint                      | YES         | null                                                     |
| public       | security_dashboard         | unique_customers            | bigint                      | YES         | null                                                     |
| public       | shop                       | shop_id                     | integer                     | NO          | null                                                     |
| public       | shop                       | shopname                    | text                        | NO          | null                                                     |
| public       | shop                       | taxrate                     | numeric                     | NO          | null                                                     |
| public       | shop                       | shipping_price              | numeric                     | NO          | null                                                     |
| public       | shop                       | threshold_free_shipping     | numeric                     | YES         | null                                                     |
| public       | shop                       | software_company_name       | text                        | YES         | null                                                     |
| public       | shop                       | software_website_link       | text                        | YES         | null                                                     |
| public       | shop                       | software_contact_no         | text                        | YES         | null                                                     |
| public       | shop                       | is_shipping_enable          | boolean                     | NO          | false                                                    |
| public       | shop                       | max_allowed_item_quantity   | bigint                      | NO          | '50'::bigint                                             |
| public       | users                      | first_name                  | text                        | NO          | ''::text                                                 |
| public       | users                      | last_name                   | text                        | YES         | ''::text                                                 |
| public       | users                      | phone_number                | text                        | YES         | ''::text                                                 |
| public       | users                      | email                       | text                        | NO          | ''::text                                                 |
| public       | users                      | dob                         | timestamp with time zone    | YES         | null                                                     |
| public       | users                      | created_at                  | timestamp with time zone    | YES         | (now() AT TIME ZONE 'utc'::text)                         |
| public       | users                      | gender                      | USER-DEFINED                | YES         | null                                                     |
| public       | users                      | user_id                     | integer                     | NO          | null                                                     |
| public       | users                      | auth_uid                    | uuid                        | YES         | null                                                     |
| public       | vendors                    | vendor_id                   | integer                     | NO          | null                                                     |
| public       | vendors                    | phone_number                | text                        | YES         | ''::text                                                 |
| public       | vendors                    | first_name                  | text                        | NO          | ''::text                                                 |
| public       | vendors                    | last_name                   | text                        | YES         | ''::text                                                 |
| public       | vendors                    | cnic                        | text                        | NO          | ''::text                                                 |
| public       | vendors                    | email                       | text                        | NO          | ''::text                                                 |
| public       | vendors                    | created_at                  | timestamp with time zone    | YES         | now()                                                    |
| public       | wishlist                   | wishlist_id                 | bigint                      | NO          | null                                                     |
| public       | wishlist                   | created_at                  | timestamp with time zone    | NO          | now()                                                    |
| public       | wishlist                   | product_id                  | integer                     | YES         | null                                                     |
| public       | wishlist                   | customer_id                 | integer                     | YES         | null                                                     |
| realtime     | messages                   | topic                       | text                        | NO          | null                                                     |
| realtime     | messages                   | extension                   | text                        | NO          | null                                                     |
| realtime     | messages                   | payload                     | jsonb                       | YES         | null                                                     |
| realtime     | messages                   | event                       | text                        | YES         | null                                                     |
| realtime     | messages                   | private                     | boolean                     | YES         | false                                                    |
| realtime     | messages                   | updated_at                  | timestamp without time zone | NO          | now()                                                    |
| realtime     | messages                   | inserted_at                 | timestamp without time zone | NO          | now()                                                    |
| realtime     | messages                   | id                          | uuid                        | NO          | gen_random_uuid()                                        |
| realtime     | messages_2025_08_20        | topic                       | text                        | NO          | null                                                     |
| realtime     | messages_2025_08_20        | extension                   | text                        | NO          | null                                                     |
| realtime     | messages_2025_08_20        | payload                     | jsonb                       | YES         | null                                                     |
| realtime     | messages_2025_08_20        | event                       | text                        | YES         | null                                                     |
| realtime     | messages_2025_08_20        | private                     | boolean                     | YES         | false                                                    |
| realtime     | messages_2025_08_20        | updated_at                  | timestamp without time zone | NO          | now()                                                    |
| realtime     | messages_2025_08_20        | inserted_at                 | timestamp without time zone | NO          | now()                                                    |
| realtime     | messages_2025_08_20        | id                          | uuid                        | NO          | gen_random_uuid()                                        |
| realtime     | messages_2025_08_21        | topic                       | text                        | NO          | null                                                     |
| realtime     | messages_2025_08_21        | extension                   | text                        | NO          | null                                                     |
| realtime     | messages_2025_08_21        | payload                     | jsonb                       | YES         | null                                                     |
| realtime     | messages_2025_08_21        | event                       | text                        | YES         | null                                                     |
| realtime     | messages_2025_08_21        | private                     | boolean                     | YES         | false                                                    |
| realtime     | messages_2025_08_21        | updated_at                  | timestamp without time zone | NO          | now()                                                    |
| realtime     | messages_2025_08_21        | inserted_at                 | timestamp without time zone | NO          | now()                                                    |
| realtime     | messages_2025_08_21        | id                          | uuid                        | NO          | gen_random_uuid()                                        |
| realtime     | messages_2025_08_22        | topic                       | text                        | NO          | null                                                     |
| realtime     | messages_2025_08_22        | extension                   | text                        | NO          | null                                                     |
| realtime     | messages_2025_08_22        | payload                     | jsonb                       | YES         | null                                                     |
| realtime     | messages_2025_08_22        | event                       | text                        | YES         | null                                                     |
| realtime     | messages_2025_08_22        | private                     | boolean                     | YES         | false                                                    |
| realtime     | messages_2025_08_22        | updated_at                  | timestamp without time zone | NO          | now()                                                    |
| realtime     | messages_2025_08_22        | inserted_at                 | timestamp without time zone | NO          | now()                                                    |
| realtime     | messages_2025_08_22        | id                          | uuid                        | NO          | gen_random_uuid()                                        |
| realtime     | messages_2025_08_23        | topic                       | text                        | NO          | null                                                     |
| realtime     | messages_2025_08_23        | extension                   | text                        | NO          | null                                                     |
| realtime     | messages_2025_08_23        | payload                     | jsonb                       | YES         | null                                                     |
| realtime     | messages_2025_08_23        | event                       | text                        | YES         | null                                                     |
| realtime     | messages_2025_08_23        | private                     | boolean                     | YES         | false                                                    |
| realtime     | messages_2025_08_23        | updated_at                  | timestamp without time zone | NO          | now()                                                    |
| realtime     | messages_2025_08_23        | inserted_at                 | timestamp without time zone | NO          | now()                                                    |
| realtime     | messages_2025_08_23        | id                          | uuid                        | NO          | gen_random_uuid()                                        |
| realtime     | messages_2025_08_24        | topic                       | text                        | NO          | null                                                     |
| realtime     | messages_2025_08_24        | extension                   | text                        | NO          | null                                                     |
| realtime     | messages_2025_08_24        | payload                     | jsonb                       | YES         | null                                                     |
| realtime     | messages_2025_08_24        | event                       | text                        | YES         | null                                                     |
| realtime     | messages_2025_08_24        | private                     | boolean                     | YES         | false                                                    |
| realtime     | messages_2025_08_24        | updated_at                  | timestamp without time zone | NO          | now()                                                    |
| realtime     | messages_2025_08_24        | inserted_at                 | timestamp without time zone | NO          | now()                                                    |
| realtime     | messages_2025_08_24        | id                          | uuid                        | NO          | gen_random_uuid()                                        |
| realtime     | schema_migrations          | version                     | bigint                      | NO          | null                                                     |
| realtime     | schema_migrations          | inserted_at                 | timestamp without time zone | YES         | null                                                     |
| realtime     | subscription               | id                          | bigint                      | NO          | null                                                     |
| realtime     | subscription               | subscription_id             | uuid                        | NO          | null                                                     |
| realtime     | subscription               | entity                      | regclass                    | NO          | null                                                     |
| realtime     | subscription               | filters                     | ARRAY                       | NO          | '{}'::realtime.user_defined_filter[]                     |
| realtime     | subscription               | claims                      | jsonb                       | NO          | null                                                     |
| realtime     | subscription               | claims_role                 | regrole                     | NO          | null                                                     |
| realtime     | subscription               | created_at                  | timestamp without time zone | NO          | timezone('utc'::text, now())                             |
| storage      | buckets                    | id                          | text                        | NO          | null                                                     |
| storage      | buckets                    | name                        | text                        | NO          | null                                                     |
| storage      | buckets                    | owner                       | uuid                        | YES         | null                                                     |
| storage      | buckets                    | created_at                  | timestamp with time zone    | YES         | now()                                                    |
| storage      | buckets                    | updated_at                  | timestamp with time zone    | YES         | now()                                                    |
| storage      | buckets                    | public                      | boolean                     | YES         | false                                                    |
| storage      | buckets                    | avif_autodetection          | boolean                     | YES         | false                                                    |
| storage      | buckets                    | file_size_limit             | bigint                      | YES         | null                                                     |
| storage      | buckets                    | allowed_mime_types          | ARRAY                       | YES         | null                                                     |
| storage      | buckets                    | owner_id                    | text                        | YES         | null                                                     |
| storage      | migrations                 | id                          | integer                     | NO          | null                                                     |
| storage      | migrations                 | name                        | character varying           | NO          | null                                                     |
| storage      | migrations                 | hash                        | character varying           | NO          | null                                                     |
| storage      | migrations                 | executed_at                 | timestamp without time zone | YES         | CURRENT_TIMESTAMP                                        |
| storage      | objects                    | id                          | uuid                        | NO          | gen_random_uuid()                                        |
| storage      | objects                    | bucket_id                   | text                        | YES         | null                                                     |
| storage      | objects                    | name                        | text                        | YES         | null                                                     |
| storage      | objects                    | owner                       | uuid                        | YES         | null                                                     |
| storage      | objects                    | created_at                  | timestamp with time zone    | YES         | now()                                                    |
| storage      | objects                    | updated_at                  | timestamp with time zone    | YES         | now()                                                    |
| storage      | objects                    | last_accessed_at            | timestamp with time zone    | YES         | now()                                                    |
| storage      | objects                    | metadata                    | jsonb                       | YES         | null                                                     |
| storage      | objects                    | path_tokens                 | ARRAY                       | YES         | null                                                     |
| storage      | objects                    | version                     | text                        | YES         | null                                                     |
| storage      | objects                    | owner_id                    | text                        | YES         | null                                                     |
| storage      | objects                    | user_metadata               | jsonb                       | YES         | null                                                     |
| storage      | s3_multipart_uploads       | id                          | text                        | NO          | null                                                     |
| storage      | s3_multipart_uploads       | in_progress_size            | bigint                      | NO          | 0                                                        |
| storage      | s3_multipart_uploads       | upload_signature            | text                        | NO          | null                                                     |
| storage      | s3_multipart_uploads       | bucket_id                   | text                        | NO          | null                                                     |
| storage      | s3_multipart_uploads       | key                         | text                        | NO          | null                                                     |
| storage      | s3_multipart_uploads       | version                     | text                        | NO          | null                                                     |
| storage      | s3_multipart_uploads       | owner_id                    | text                        | YES         | null                                                     |
| storage      | s3_multipart_uploads       | created_at                  | timestamp with time zone    | NO          | now()                                                    |
| storage      | s3_multipart_uploads       | user_metadata               | jsonb                       | YES         | null                                                     |
| storage      | s3_multipart_uploads_parts | id                          | uuid                        | NO          | gen_random_uuid()                                        |
| storage      | s3_multipart_uploads_parts | upload_id                   | text                        | NO          | null                                                     |
| storage      | s3_multipart_uploads_parts | size                        | bigint                      | NO          | 0                                                        |
| storage      | s3_multipart_uploads_parts | part_number                 | integer                     | NO          | null                                                     |
| storage      | s3_multipart_uploads_parts | bucket_id                   | text                        | NO          | null                                                     |
| storage      | s3_multipart_uploads_parts | key                         | text                        | NO          | null                                                     |
| storage      | s3_multipart_uploads_parts | etag                        | text                        | NO          | null                                                     |
| storage      | s3_multipart_uploads_parts | owner_id                    | text                        | YES         | null                                                     |
| storage      | s3_multipart_uploads_parts | version                     | text                        | NO          | null                                                     |
| storage      | s3_multipart_uploads_parts | created_at                  | timestamp with time zone    | NO          | now()                                                    |
| vault        | decrypted_secrets          | id                          | uuid                        | YES         | null                                                     |
| vault        | decrypted_secrets          | name                        | text                        | YES         | null                                                     |
| vault        | decrypted_secrets          | description                 | text                        | YES         | null                                                     |
| vault        | decrypted_secrets          | secret                      | text                        | YES         | null                                                     |
| vault        | decrypted_secrets          | decrypted_secret            | text                        | YES         | null                                                     |
| vault        | decrypted_secrets          | key_id                      | uuid                        | YES         | null                                                     |
| vault        | decrypted_secrets          | nonce                       | bytea                       | YES         | null                                                     |
| vault        | decrypted_secrets          | created_at                  | timestamp with time zone    | YES         | null                                                     |
| vault        | decrypted_secrets          | updated_at                  | timestamp with time zone    | YES         | null                                                     |
| vault        | secrets                    | id                          | uuid                        | NO          | gen_random_uuid()                                        |
| vault        | secrets                    | name                        | text                        | YES         | null                                                     |
| vault        | secrets                    | description                 | text                        | NO          | ''::text                                                 |
| vault        | secrets                    | secret                      | text                        | NO          | null                                                     |
| vault        | secrets                    | key_id                      | uuid                        | YES         | null                                                     |
| vault        | secrets                    | nonce                       | bytea                       | YES         | vault._crypto_aead_det_noncegen()                        |
| vault        | secrets                    | created_at                  | timestamp with time zone    | NO          | CURRENT_TIMESTAMP                                        |
| vault        | secrets                    | updated_at                  | timestamp with time zone    | NO          | CURRENT_TIMESTAMP                                        |