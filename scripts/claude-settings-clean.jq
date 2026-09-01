del(.model, .effortLevel) as $in
| reduce (
    "env",
    "permissions",
    "hooks",
    "tui",
    "attribution",
    "autoMemoryEnabled",
    "skipDangerousModePermissionPrompt",
    "skipAutoPermissionPrompt",
    "theme",
    "agentPushNotifEnabled"
  ) as $k (
    {};
    if ($in | has($k)) then . + { ($k): $in[$k] } else . end
  )
  + (
    $in
    | del(
        .env,
        .permissions,
        .hooks,
        .tui,
        .attribution,
        .autoMemoryEnabled,
        .skipDangerousModePermissionPrompt,
        .skipAutoPermissionPrompt,
        .theme,
        .agentPushNotifEnabled
      )
  )
