# Tmuxifier file

session_root "$HOME/Workspace/CaptainDash"

if initialize_session 'sncf-wall' ; then

  new_window 'sncf-backend-api'
    run_cmd 'cd "$HOME/Workspace/CaptainDash/sncf-backend/api"'
    run_cmd 'clear'
  split_h 50
    run_cmd 'cd "$HOME/Workspace/CaptainDash/sncf-backend/api"'
    run_cmd 'clear'

  new_window 'sncf-backend-web'
    run_cmd 'cd "$HOME/Workspace/CaptainDash/sncf-backend/web"'
    run_cmd 'clear'
  split_h 50
    run_cmd 'cd "$HOME/Workspace/CaptainDash/sncf-backend/web"'
    run_cmd 'clear'

  new_window 'sncf-wall'
    run_cmd 'cd "$HOME/Workspace/CaptainDash/sncf-wall"'
    run_cmd 'clear'
  split_h 50
    run_cmd 'cd "$HOME/Workspace/CaptainDash/sncf-wall"'
    run_cmd 'clear'

  select_window 'sncf-wall'

fi

finalize_and_go_to_session
