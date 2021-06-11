https://www.appsdeveloperblog.com/keycloak-rest-api-create-a-new-user/
TOKEN=$(curl -s \
  -d "client_id=admin-cli" \
  -d "username=admin" \
  -d "password=admin" \
  -d "grant_type=password" \
  "http://localhost:8080/auth/realms/master/protocol/openid-connect/token" | jq -r .access_token)

curl \
  -H "Authorization: bearer ${TOKEN}" \
  "http://localhost:8080/auth/admin/realms/master"


curl --location --request POST 'http://localhost:8080/auth/admin/realms/master/users' \
--header "Content-Type: application/json" \
--header "Authorization: Bearer ${TOKEN}" \
--data-raw '{"firstName":"Sergey","lastName":"Kargopolov", "email":"test@test.com", "enabled":"true", "username":"app-user"}'