#!/bin/sh
set -ex

dart pub global deactivate dart_pre_commit || true
dart pub global activate dart_pre_commit
echo "#!/bin/sh" > .git/hooks/pre-commit
echo "dart pub global run dart_pre_commit" >> .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
