composer.json
```json
{
    "require": {
        "cweagans/composer-patches": "^2.0"
    },
    "config": {
        "allow-plugins": {
            "cweagans/composer-patches": true
        }
    },
    "extra": {
        "enable-patching": true
    },
    "scripts": {
        "update:patches": [
            "curl -s -o patches.json https://raw.githubusercontent.com/awkirin/awk-patches/refs/heads/main/patches.json"
        ],
        "pre-install-cmd": [
            "@update:patches"
        ],
        "pre-update-cmd": [
            "@update:patches"
        ]
    }
}
```
