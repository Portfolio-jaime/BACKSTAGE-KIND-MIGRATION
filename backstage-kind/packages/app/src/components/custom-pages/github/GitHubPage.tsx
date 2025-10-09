import React, { useState } from 'react';
import {
  Page,
  Header,
  Content,
  ContentHeader,
  HeaderLabel,
  SupportButton,
} from '@backstage/core-components';
import { Grid, Card, CardContent, Typography, Tabs, Tab, Box, Chip, Button } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import GitHubIcon from '@material-ui/icons/GitHub';
import CodeIcon from '@material-ui/icons/Code';
import PeopleIcon from '@material-ui/icons/People';
import SecurityIcon from '@material-ui/icons/Security';
import SettingsIcon from '@material-ui/icons/Settings';

const useStyles = makeStyles(theme => ({
  statCard: {
    textAlign: 'center',
    padding: theme.spacing(3),
  },
  statValue: {
    fontSize: '2.5rem',
    fontWeight: 'bold',
    color: theme.palette.primary.main,
  },
  statLabel: {
    fontSize: '1rem',
    color: theme.palette.text.secondary,
    marginTop: theme.spacing(1),
  },
  tabPanel: {
    paddingTop: theme.spacing(3),
  },
  linkCard: {
    marginBottom: theme.spacing(2),
    cursor: 'pointer',
    '&:hover': {
      boxShadow: theme.shadows[4],
    },
  },
  codeBlock: {
    padding: theme.spacing(2),
    backgroundColor: '#f5f5f5',
    borderRadius: theme.shape.borderRadius,
    fontFamily: 'monospace',
    fontSize: '0.875rem',
    overflow: 'auto',
  },
  chip: {
    margin: theme.spacing(0.5),
  },
  repoCard: {
    marginBottom: theme.spacing(2),
    '&:hover': {
      boxShadow: theme.shadows[3],
    },
  },
  languageChip: {
    marginRight: theme.spacing(1),
  },
}));

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;
  const classes = useStyles();

  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`github-tabpanel-${index}`}
      aria-labelledby={`github-tab-${index}`}
      {...other}
    >
      {value === index && (
        <Box className={classes.tabPanel}>
          {children}
        </Box>
      )}
    </div>
  );
}

export const GitHubPage = () => {
  const classes = useStyles();
  const [value, setValue] = useState(0);

  const handleChange = (_event: React.ChangeEvent<{}>, newValue: number) => {
    setValue(newValue);
  };

  const openInNewTab = (url: string) => {
    window.open(url, '_blank', 'noopener,noreferrer');
  };

  return (
    <Page themeId="tool">
      <Header title="GitHub Integration" subtitle="Repository Management & Collaboration">
        <HeaderLabel label="Organization" value="Your Organization" />
        <HeaderLabel label="Type" value="Version Control" />
      </Header>
      <Content>
        <ContentHeader title="GitHub - Source Code Management">
          <SupportButton>
            Manage repositories, pull requests, and collaboration workflows
          </SupportButton>
        </ContentHeader>

        {/* Quick Stats */}
        <Grid container spacing={3} style={{ marginBottom: '24px' }}>
          <Grid item xs={12} sm={3}>
            <Card className={classes.statCard}>
              <CardContent>
                <CodeIcon style={{ fontSize: 48, color: '#24292e' }} />
                <Typography className={classes.statValue}>
                  Active
                </Typography>
                <Typography className={classes.statLabel}>
                  Repositories
                </Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={3}>
            <Card className={classes.statCard}>
              <CardContent>
                <PeopleIcon style={{ fontSize: 48, color: '#0366d6' }} />
                <Typography className={classes.statValue}>
                  Team
                </Typography>
                <Typography className={classes.statLabel}>
                  Contributors
                </Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={3}>
            <Card className={classes.statCard}>
              <CardContent>
                <GitHubIcon style={{ fontSize: 48, color: '#28a745' }} />
                <Typography className={classes.statValue}>
                  Open
                </Typography>
                <Typography className={classes.statLabel}>
                  Pull Requests
                </Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={3}>
            <Card className={classes.statCard}>
              <CardContent>
                <SecurityIcon style={{ fontSize: 48, color: '#f66a0a' }} />
                <Typography className={classes.statValue}>
                  Protected
                </Typography>
                <Typography className={classes.statLabel}>
                  Branch Protection
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        </Grid>

        {/* Tabs */}
        <Card>
          <Tabs
            value={value}
            onChange={handleChange}
            indicatorColor="primary"
            textColor="primary"
            variant="fullWidth"
          >
            <Tab label="Repositories" icon={<CodeIcon />} />
            <Tab label="Workflows" icon={<SettingsIcon />} />
            <Tab label="Quick Guide" icon={<GitHubIcon />} />
          </Tabs>

          <TabPanel value={value} index={0}>
            <Typography variant="h6" gutterBottom>
              Active Repositories
            </Typography>
            <Typography variant="body2" color="textSecondary" paragraph>
              Platform repositories and their status
            </Typography>

            <Grid container spacing={2}>
              <Grid item xs={12} md={6}>
                <Card className={classes.repoCard}>
                  <CardContent>
                    <Box display="flex" justifyContent="space-between" alignItems="center">
                      <Typography variant="h6">
                        <CodeIcon style={{ verticalAlign: 'middle', marginRight: 8 }} />
                        backstage-kind-migration
                      </Typography>
                      <Chip label="Active" color="primary" size="small" />
                    </Box>
                    <Typography variant="body2" color="textSecondary" paragraph style={{ marginTop: 8 }}>
                      Backstage platform deployment on Kind Kubernetes cluster
                    </Typography>
                    <Box mt={1}>
                      <Chip label="TypeScript" size="small" className={classes.languageChip} />
                      <Chip label="Kubernetes" size="small" className={classes.languageChip} />
                      <Chip label="Docker" size="small" />
                    </Box>
                    <Box mt={2}>
                      <Button
                        size="small"
                        color="primary"
                        onClick={() => openInNewTab('https://github.com/your-org/backstage-kind-migration')}
                      >
                        View Repository
                      </Button>
                    </Box>
                  </CardContent>
                </Card>
              </Grid>

              <Grid item xs={12} md={6}>
                <Card className={classes.repoCard}>
                  <CardContent>
                    <Box display="flex" justifyContent="space-between" alignItems="center">
                      <Typography variant="h6">
                        <CodeIcon style={{ verticalAlign: 'middle', marginRight: 8 }} />
                        platform-infrastructure
                      </Typography>
                      <Chip label="Active" color="primary" size="small" />
                    </Box>
                    <Typography variant="body2" color="textSecondary" paragraph style={{ marginTop: 8 }}>
                      Infrastructure as Code for platform services
                    </Typography>
                    <Box mt={1}>
                      <Chip label="YAML" size="small" className={classes.languageChip} />
                      <Chip label="Helm" size="small" className={classes.languageChip} />
                      <Chip label="ArgoCD" size="small" />
                    </Box>
                    <Box mt={2}>
                      <Button
                        size="small"
                        color="primary"
                        onClick={() => openInNewTab('https://github.com/your-org/platform-infrastructure')}
                      >
                        View Repository
                      </Button>
                    </Box>
                  </CardContent>
                </Card>
              </Grid>

              <Grid item xs={12} md={6}>
                <Card className={classes.repoCard}>
                  <CardContent>
                    <Box display="flex" justifyContent="space-between" alignItems="center">
                      <Typography variant="h6">
                        <CodeIcon style={{ verticalAlign: 'middle', marginRight: 8 }} />
                        monitoring-configs
                      </Typography>
                      <Chip label="Active" color="primary" size="small" />
                    </Box>
                    <Typography variant="body2" color="textSecondary" paragraph style={{ marginTop: 8 }}>
                      Prometheus, Grafana, and AlertManager configurations
                    </Typography>
                    <Box mt={1}>
                      <Chip label="YAML" size="small" className={classes.languageChip} />
                      <Chip label="PromQL" size="small" className={classes.languageChip} />
                      <Chip label="Grafana" size="small" />
                    </Box>
                    <Box mt={2}>
                      <Button
                        size="small"
                        color="primary"
                        onClick={() => openInNewTab('https://github.com/your-org/monitoring-configs')}
                      >
                        View Repository
                      </Button>
                    </Box>
                  </CardContent>
                </Card>
              </Grid>

              <Grid item xs={12} md={6}>
                <Card className={classes.repoCard}>
                  <CardContent>
                    <Box display="flex" justifyContent="space-between" alignItems="center">
                      <Typography variant="h6">
                        <CodeIcon style={{ verticalAlign: 'middle', marginRight: 8 }} />
                        backstage-plugins
                      </Typography>
                      <Chip label="Active" color="primary" size="small" />
                    </Box>
                    <Typography variant="body2" color="textSecondary" paragraph style={{ marginTop: 8 }}>
                      Custom Backstage plugins and components
                    </Typography>
                    <Box mt={1}>
                      <Chip label="TypeScript" size="small" className={classes.languageChip} />
                      <Chip label="React" size="small" className={classes.languageChip} />
                      <Chip label="Backstage" size="small" />
                    </Box>
                    <Box mt={2}>
                      <Button
                        size="small"
                        color="primary"
                        onClick={() => openInNewTab('https://github.com/your-org/backstage-plugins')}
                      >
                        View Repository
                      </Button>
                    </Box>
                  </CardContent>
                </Card>
              </Grid>
            </Grid>
          </TabPanel>

          <TabPanel value={value} index={1}>
            <Typography variant="h6" gutterBottom>
              GitHub Actions Workflows
            </Typography>
            <Typography variant="body2" color="textSecondary" paragraph>
              CI/CD pipelines and automation workflows
            </Typography>

            <Box mb={3}>
              <Typography variant="subtitle1" gutterBottom>
                <strong>Build and Deploy Backstage</strong>
              </Typography>
              <Box className={classes.codeBlock}>
                <Typography component="pre" style={{ margin: 0 }}>
{`name: Build and Deploy Backstage
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'yarn'

      - name: Install dependencies
        run: yarn install --frozen-lockfile

      - name: Build Backstage
        run: yarn build:backend

      - name: Build Docker image
        run: |
          docker build -t backstage:latest .

      - name: Push to registry
        run: |
          docker push your-registry/backstage:latest`}
                </Typography>
              </Box>
            </Box>

            <Box mb={3}>
              <Typography variant="subtitle1" gutterBottom>
                <strong>Infrastructure Sync</strong>
              </Typography>
              <Box className={classes.codeBlock}>
                <Typography component="pre" style={{ margin: 0 }}>
{`name: Sync Infrastructure
on:
  push:
    paths:
      - 'kubernetes/**'
      - 'helm/**'
    branches: [main]

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup kubectl
        uses: azure/setup-kubectl@v3

      - name: Apply Kubernetes manifests
        run: |
          kubectl apply -f kubernetes/ --recursive

      - name: Verify deployment
        run: |
          kubectl rollout status deployment/backstage -n backstage`}
                </Typography>
              </Box>
            </Box>

            <Box mb={3}>
              <Typography variant="subtitle1" gutterBottom>
                <strong>Security Scanning</strong>
              </Typography>
              <Box className={classes.codeBlock}>
                <Typography component="pre" style={{ margin: 0 }}>
{`name: Security Scan
on:
  schedule:
    - cron: '0 0 * * *'  # Daily
  workflow_dispatch:

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-results.sarif'

      - name: Upload results to GitHub Security
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'`}
                </Typography>
              </Box>
            </Box>
          </TabPanel>

          <TabPanel value={value} index={2}>
            <Typography variant="h6" gutterBottom>
              Git Workflow Best Practices
            </Typography>

            <Box mb={3}>
              <Card style={{ padding: '16px' }}>
                <Box mb={2}>
                  <Chip label="Feature Branches" color="primary" className={classes.chip} />
                  <Chip label="Pull Requests" color="primary" className={classes.chip} />
                  <Chip label="Code Review" color="primary" className={classes.chip} />
                  <Chip label="Protected Branches" color="primary" className={classes.chip} />
                </Box>
                <Typography variant="body2" paragraph>
                  <strong>1. Branch Naming:</strong> Use prefixes like feature/, bugfix/, hotfix/
                </Typography>
                <Typography variant="body2" paragraph>
                  <strong>2. Commit Messages:</strong> Follow conventional commits (feat:, fix:, docs:)
                </Typography>
                <Typography variant="body2" paragraph>
                  <strong>3. Pull Requests:</strong> Require at least 1 approval before merging
                </Typography>
                <Typography variant="body2" paragraph>
                  <strong>4. Branch Protection:</strong> Protect main/master branch from direct pushes
                </Typography>
              </Card>
            </Box>

            <Box mb={3}>
              <Typography variant="h6" gutterBottom>
                Common Git Commands
              </Typography>
              <Box className={classes.codeBlock}>
                <Typography component="pre" style={{ margin: 0 }}>
{`# Create and switch to feature branch
git checkout -b feature/my-new-feature

# Stage and commit changes
git add .
git commit -m "feat: add new monitoring page"

# Push to remote
git push origin feature/my-new-feature

# Update local main branch
git checkout main
git pull origin main

# Rebase feature branch
git checkout feature/my-new-feature
git rebase main

# Squash commits (interactive rebase)
git rebase -i HEAD~3

# Stash changes
git stash
git stash pop

# View commit history
git log --oneline --graph --all

# Cherry-pick a commit
git cherry-pick <commit-hash>`}
                </Typography>
              </Box>
            </Box>

            <Box mb={3}>
              <Typography variant="h6" gutterBottom>
                GitHub CLI (gh) Commands
              </Typography>
              <Box className={classes.codeBlock}>
                <Typography component="pre" style={{ margin: 0 }}>
{`# Create a pull request
gh pr create --title "Add monitoring page" --body "Description"

# List pull requests
gh pr list

# View PR details
gh pr view 123

# Review a PR
gh pr review 123 --approve

# Merge a PR
gh pr merge 123 --squash

# List repositories
gh repo list

# Clone repository
gh repo clone org/repo

# View issues
gh issue list

# Create an issue
gh issue create --title "Bug report" --body "Description"`}
                </Typography>
              </Box>
            </Box>

            <Box mb={3}>
              <Typography variant="h6" gutterBottom>
                Branch Protection Rules
              </Typography>
              <Card style={{ padding: '16px', backgroundColor: '#f5f5f5' }}>
                <Typography variant="body2" component="div">
                  <ul style={{ margin: 0, paddingLeft: 20 }}>
                    <li>Require pull request reviews before merging (minimum 1 approval)</li>
                    <li>Require status checks to pass before merging</li>
                    <li>Require branches to be up to date before merging</li>
                    <li>Require linear history (no merge commits)</li>
                    <li>Require signed commits</li>
                    <li>Include administrators in restrictions</li>
                    <li>Restrict who can push to matching branches</li>
                    <li>Allow force pushes: Disabled</li>
                    <li>Allow deletions: Disabled</li>
                  </ul>
                </Typography>
              </Card>
            </Box>

            <Box mb={3}>
              <Typography variant="h6" gutterBottom>
                Conventional Commits
              </Typography>
              <Box className={classes.codeBlock}>
                <Typography component="pre" style={{ margin: 0 }}>
{`# Format: <type>(<scope>): <description>

feat: add new feature
fix: fix bug in authentication
docs: update README documentation
style: format code
refactor: restructure monitoring components
test: add unit tests
chore: update dependencies
perf: improve query performance
ci: update GitHub Actions workflow

# Examples:
feat(monitoring): add Prometheus integration
fix(auth): resolve token expiration issue
docs(api): document new endpoints
refactor(ui): simplify component structure`}
                </Typography>
              </Box>
            </Box>
          </TabPanel>
        </Card>
      </Content>
    </Page>
  );
};
