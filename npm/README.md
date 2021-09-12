```
const metascoreQuery = useMemo(() => createActor(), []);

metascoreQuery.getGames().then(console.log);
```