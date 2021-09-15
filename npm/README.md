```shell
# Chore
npm run declarations
```

```typescript
// Use
const metascoreQuery = useMemo(() => createActor(), []);
metascoreQuery.getGames().then(console.log);
```