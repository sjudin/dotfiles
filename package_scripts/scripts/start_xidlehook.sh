# Run xidlehook
xidlehook \
  --socket /tmp/xidlehook.sock \
  `# Don't lock when there's a fullscreen application` \
  --not-when-fullscreen \
  `# Don't lock when there's audio playing` \
  --not-when-audio \
  `# Dim the screen after 60 seconds, undim if user becomes active` \
  --timer 60 \
    '~/scripts/set_brigthness.sh 0.3' \
    '~/scripts/set_brigthness.sh 1.0' \
  `# Undim & lock after 10 more seconds` \
  --timer 10 \
    '~/scripts/set_brigthness.sh 1.0; $HOME/scripts/fuzzy_lock.sh' \
    '' \
  --timer 30 \
    'xset dpms force off' \
    '~/scripts/set_brigthness.sh 1.0' \
  `# Finally, suspend an hour after it locks` \
  --timer 3600 \
    'systemctl suspend' \
    ''
