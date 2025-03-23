#!/bin/bash

echo "Locating Firebase Storage files..."
STORAGE_FILE=$(find . -path "*/FirebaseStorage/*/Storage.swift" 2>/dev/null)

if [ -z "$STORAGE_FILE" ]; then
  echo "ERROR: Storage.swift not found. Make sure pods are installed."
  echo "Run 'pod install' first, then try again."
  exit 1
fi

echo "Found Storage.swift at: $STORAGE_FILE"

# Make a backup
cp "$STORAGE_FILE" "${STORAGE_FILE}.backup"
echo "Created backup at ${STORAGE_FILE}.backup"

# Replace the problematic lines
sed -i '' 's/provider.storage/provider?.storage/g' "$STORAGE_FILE"
sed -i '' 's/auth = auth/auth = (auth as? any AuthInterop) ?? FIRAuthInteropFake()/g' "$STORAGE_FILE"
sed -i '' 's/appCheck = appCheck/appCheck = (appCheck as? any AppCheckInterop) ?? FIRAppCheckInteropFake()/g' "$STORAGE_FILE"

# Check if FIRAuthInteropFake doesn't exist, and create it if needed
if grep -q "FIRAuthInteropFake" "$STORAGE_FILE" && ! grep -q "class FIRAuthInteropFake" "$STORAGE_FILE"; then
  echo "Adding FIRAuthInteropFake class..."
  cat >> "$STORAGE_FILE" << 'EOF'

// ADDED BY FIX SCRIPT
private class FIRAuthInteropFake: AuthInterop {
  func getUserID() -> String? { return nil }
  func getIDToken(completion: @escaping (String?, Error?) -> Void) { completion(nil, nil) }
  func getIDToken(forceRefresh: Bool, completion: @escaping (String?, Error?) -> Void) { completion(nil, nil) }
}

private class FIRAppCheckInteropFake: AppCheckInterop {
  func getToken(forcingRefresh: Bool, completion: @escaping (AppCheckToken?, Error?) -> Void) { completion(nil, nil) }
}
EOF
fi

echo "Fixed Storage.swift successfully!"
