# workflow for this template

First step after templating and cloning this template
```text
git checkout --orphan signatures
git rm -rf .
git commit --allow-empty -m "Initial signatures branch"
git push origin signatures
git checkout main
```

Second step:

On the GitHub webpage, navigate to the `signatures` branch, create a file named cla.json, paste the following inside, and commit.
```
{ 
"signedContributors": [] 
}
```
