# Julia API Reference

```@meta
CurrentModule = {{PKG}}
```

## Client

```@docs
Client
```

## Auth

```@docs
Auth
NoAuth
BearerToken
APIKey
BasicAuth
{{PKG}}.apply!
{{PKG}}.build_pre_request_hook
```

## Errors

```@docs
APIError
NetworkError
ClientError
ServerError
AuthError
RateLimitError
TimeoutError
```

## Reliability

```@docs
RetryPolicy
with_retry
TokenBucket
acquire!
with_rate_limit
with_timeout
```

## Pagination

```@docs
paginate_cursor
paginate_offset
paginate_pagenum
```
