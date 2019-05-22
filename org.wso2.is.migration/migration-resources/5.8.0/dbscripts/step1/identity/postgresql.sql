ALTER TABLE IDN_SAML2_ASSERTION_STORE ADD COLUMN ASSERTION BYTEA;

DO $$ BEGIN BEGIN ALTER TABLE IDN_OAUTH2_AUTHORIZATION_CODE ADD COLUMN IDP_ID INTEGER NOT NULL DEFAULT -1;	 ALTER TABLE IDN_OAUTH2_AUTHORIZATION_CODE ALTER COLUMN IDP_ID DROP DEFAULT; EXCEPTION WHEN duplicate_column THEN RAISE NOTICE 'column IDP_ID already exists in IDN_OAUTH2_AUTHORIZATION_CODE.'; END;	BEGIN ALTER TABLE IDN_OAUTH2_ACCESS_TOKEN ADD COLUMN IDP_ID INTEGER NOT NULL DEFAULT -1;	 ALTER TABLE IDN_OAUTH2_ACCESS_TOKEN ALTER COLUMN IDP_ID DROP DEFAULT; EXCEPTION WHEN duplicate_column THEN RAISE NOTICE 'column IDP_ID already exists in IDN_OAUTH2_ACCESS_TOKEN.'; END;	BEGIN ALTER TABLE IDN_OAUTH2_ACCESS_TOKEN_AUDIT ADD COLUMN IDP_ID INTEGER NOT NULL DEFAULT -1;	 ALTER TABLE IDN_OAUTH2_ACCESS_TOKEN_AUDIT ALTER COLUMN IDP_ID DROP DEFAULT; EXCEPTION WHEN duplicate_column THEN RAISE NOTICE 'column IDP_ID already exists in IDN_OAUTH2_ACCESS_TOKEN_AUDIT.'; END; END$$;

CREATE OR REPLACE FUNCTION add_idp_id_to_con_app_key_if_token_id_present() RETURNS void AS $$ begin if (SELECT count(*) FROM pg_indexes WHERE tablename = 'idn_oauth2_access_token' AND indexname = 'con_app_key' AND indexdef LIKE '%' || 'token_id' || '%') > 0 then ALTER TABLE IDN_OAUTH2_ACCESS_TOKEN DROP CONSTRAINT IF EXISTS CON_APP_KEY; ALTER TABLE IDN_OAUTH2_ACCESS_TOKEN ADD CONSTRAINT CON_APP_KEY UNIQUE (CONSUMER_KEY_ID, AUTHZ_USER, TOKEN_ID, USER_DOMAIN, USER_TYPE, TOKEN_SCOPE_HASH, TOKEN_STATE, TOKEN_STATE_ID, IDP_ID); end if; END;$$ LANGUAGE plpgsql;

select add_idp_id_to_con_app_key_if_token_id_present();

CREATE TABLE IF NOT EXISTS IDN_AUTH_USER (
	USER_ID VARCHAR(255) NOT NULL,
	USER_NAME VARCHAR(255) NOT NULL,
	TENANT_ID INTEGER NOT NULL,
	DOMAIN_NAME VARCHAR(255) NOT NULL,
	IDP_ID INTEGER NOT NULL,
	PRIMARY KEY (USER_ID),
	CONSTRAINT USER_STORE_CONSTRAINT UNIQUE (USER_NAME, TENANT_ID, DOMAIN_NAME, IDP_ID));

CREATE OR REPLACE FUNCTION skip_index_if_exists(indexName varchar(64),tableName varchar(64), tableColumns varchar(64))  RETURNS void AS $$ declare s varchar(1000);  begin if to_regclass(indexName) IS NULL then s :=  CONCAT('CREATE INDEX ' , indexName , ' ON ' , tableName, tableColumns);execute s;end if;END;$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS IDN_AUTH_USER_SESSION_MAPPING (
	USER_ID VARCHAR(255) NOT NULL,
	SESSION_ID VARCHAR(255) NOT NULL,
	CONSTRAINT USER_SESSION_STORE_CONSTRAINT UNIQUE (USER_ID, SESSION_ID));

SELECT skip_index_if_exists('IDX_USER_ID', 'IDN_AUTH_USER_SESSION_MAPPING', '(USER_ID)');

SELECT skip_index_if_exists('IDX_SESSION_ID', 'IDN_AUTH_USER_SESSION_MAPPING', '(SESSION_ID)');

SELECT skip_index_if_exists('IDX_OCA_UM_TID_UD_APN','IDN_OAUTH_CONSUMER_APPS','(USERNAME,TENANT_ID,USER_DOMAIN, APP_NAME)');

SELECT skip_index_if_exists('IDX_SPI_APP','SP_INBOUND_AUTH','(APP_ID)');

SELECT skip_index_if_exists('IDX_IOP_TID_CK','IDN_OIDC_PROPERTY','(TENANT_ID,CONSUMER_KEY)');

SELECT skip_index_if_exists('IDX_AT_AU_TID_UD_TS_CKID', 'IDN_OAUTH2_ACCESS_TOKEN', '(AUTHZ_USER, TENANT_ID, USER_DOMAIN, TOKEN_STATE, CONSUMER_KEY_ID)');

SELECT skip_index_if_exists('IDX_AT_AT', 'IDN_OAUTH2_ACCESS_TOKEN', '(ACCESS_TOKEN)');

SELECT skip_index_if_exists('IDX_AT_AU_CKID_TS_UT', 'IDN_OAUTH2_ACCESS_TOKEN', '(AUTHZ_USER, CONSUMER_KEY_ID, TOKEN_STATE, USER_TYPE)');

SELECT skip_index_if_exists('IDX_AT_RTH', 'IDN_OAUTH2_ACCESS_TOKEN', '(REFRESH_TOKEN_HASH)');

SELECT skip_index_if_exists('IDX_AT_RT', 'IDN_OAUTH2_ACCESS_TOKEN', '(REFRESH_TOKEN)');

SELECT skip_index_if_exists('IDX_AC_CKID', 'IDN_OAUTH2_AUTHORIZATION_CODE', '(CONSUMER_KEY_ID)');

SELECT skip_index_if_exists('IDX_AC_TID', 'IDN_OAUTH2_AUTHORIZATION_CODE', '(TOKEN_ID)');

SELECT skip_index_if_exists('IDX_AC_AC_CKID', 'IDN_OAUTH2_AUTHORIZATION_CODEE', '(AUTHORIZATION_CODE, CONSUMER_KEY_ID)');

SELECT skip_index_if_exists('IDX_SC_TID', 'IDN_OAUTH2_SCOPEE', '(TENANT_ID)');

SELECT skip_index_if_exists('IDX_SC_N_TID', 'IDN_OAUTH2_SCOPEE', '(NAME, TENANT_ID)');

SELECT skip_index_if_exists('IDX_SB_SCPID', 'IDN_OAUTH2_SCOPE_BINDINGE', '(SCOPE_ID)');

SELECT skip_index_if_exists('IDX_OROR_TID', 'IDN_OIDC_REQ_OBJECT_REFERENCEE', '(TOKEN_ID)');

SELECT skip_index_if_exists('IDX_ATS_TID', 'IDN_OAUTH2_ACCESS_TOKEN_SCOPE', '(TOKEN_ID)');

SELECT skip_index_if_exists('IDX_AUTH_USER_UN_TID_DN', 'IDN_AUTH_USER', '(USER_NAME, TENANT_ID, DOMAIN_NAME)');

SELECT skip_index_if_exists('IDX_AUTH_USER_DN_TOD', 'IDN_AUTH_USER', '(DOMAIN_NAME, TENANT_ID)');

DROP FUNCTION skip_index_if_exists;

DROP FUNCTION add_idp_id_to_con_app_key_if_token_id_present;
