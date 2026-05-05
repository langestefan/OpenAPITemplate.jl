{
  "name": "{{PKG_LOWER}}-docs",
  "private": true,
  "type": "module",
  "scripts": {
    "docs:dev": "vitepress dev build/.documenter",
    "docs:build": "vitepress build build/.documenter",
    "docs:preview": "vitepress preview build/.documenter"
  },
  "devDependencies": {
    "vitepress": "^1.5.0",
    "vitepress-openapi": "^0.1.0"
  }
}
