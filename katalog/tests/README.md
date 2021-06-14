# Keycloak tests

## Useful info and requests

These requests have been found [here](https://www.appsdeveloperblog.com/keycloak-rest-api-create-a-new-user/):

The admin token can be retrieved by:

```bash
TOKEN=$(curl -s \
  -d "client_id=admin-cli" \
  -d "username=admin" \
  -d "password=admin" \
  -d "grant_type=password" \
  "http://localhost:8080/auth/realms/master/protocol/openid-connect/token" | jq -r .access_token)
```

Then you can test the token by requesting:

```bash
curl \
  -H "Authorization: bearer ${TOKEN}" \
  "http://localhost:8080/auth/admin/realms/master"
```

If it does not return a `40X` http status code, it is ready to use in other business like creating users:

```bash
curl --location --request POST 'http://localhost:8080/auth/admin/realms/master/users' \
--header "Content-Type: application/json" \
--header "Authorization: Bearer ${TOKEN}" \
--data-raw '{"firstName":"no","lastName":"body", "email":"hello@sighup.io", "enabled":"true", "username":"hello"}'
```
