import React, { useState } from 'react';
import {
  Page,
  Header,
  Content,
  ContentHeader,
  HeaderLabel,
  SupportButton,
} from '@backstage/core-components';
import { Grid, Card, CardContent, Typography, Tabs, Tab, Box, Chip } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import CloudSyncIcon from '@material-ui/icons/CloudSync';
import AppsIcon from '@material-ui/icons/Apps';
import SettingsIcon from '@material-ui/icons/Settings';

const useStyles = makeStyles(theme => ({
  iframe: {
    width: '100%',
    height: '800px',
    border: 'none',
    borderRadius: theme.shape.borderRadius,
  },
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
  chip: {
    margin: theme.spacing(0.5),
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
      id={`gitops-tabpanel-${index}`}
      aria-labelledby={`gitops-tab-${index}`}
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

export const GitOpsPage = () => {
  const classes = useStyles();
  const [value, setValue] = useState(0);

  const handleChange = (event: React.ChangeEvent<{}>, newValue: number) => {
    setValue(newValue);
  };

  const openInNewTab = (url: string) => {
    window.open(url, '_blank', 'noopener,noreferrer');
  };

  return (
    <Page themeId="tool">
      <Header title="GitOps Platform" subtitle="ArgoCD Continuous Delivery">
        <HeaderLabel label="Owner" value="Platform Engineering" />
        <HeaderLabel label="Lifecycle" value="Production" />
      </Header>
      <Content>
        <ContentHeader title="ArgoCD - Declarative GitOps">
          <SupportButton>
            Manage Kubernetes applications with GitOps workflows
          </SupportButton>
        </ContentHeader>

        {/* Quick Stats */}
        <Grid container spacing={3} style={{ marginBottom: '24px' }}>
          <Grid item xs={12} sm={3}>
            <Card className={classes.statCard}>
              <CardContent>
                <CloudSyncIcon style={{ fontSize: 48, color: '#EF7B4D' }} />
                <Typography className={classes.statValue}>
                  Running
                </Typography>
                <Typography className={classes.statLabel}>
                  ArgoCD Status
                </Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={3}>
            <Card className={classes.statCard}>
              <CardContent>
                <AppsIcon style={{ fontSize: 48, color: '#4CAF50' }} />
                <Typography className={classes.statValue}>
                  Active
                </Typography>
                <Typography className={classes.statLabel}>
                  Applications
                </Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={3}>
            <Card className={classes.statCard}>
              <CardContent>
                <Typography className={classes.statValue}>
                  Synced
                </Typography>
                <Typography className={classes.statLabel}>
                  Sync Status
                </Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={3}>
            <Card className={classes.statCard}>
              <CardContent>
                <Typography className={classes.statValue}>
                  Healthy
                </Typography>
                <Typography className={classes.statLabel}>
                  Health Status
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
            <Tab label="Applications" icon={<AppsIcon />} />
            <Tab label="Console" icon={<CloudSyncIcon />} />
            <Tab label="Getting Started" icon={<SettingsIcon />} />
          </Tabs>

          <TabPanel value={value} index={0}>
            <Typography variant="h6" gutterBottom>
              ArgoCD Applications
            </Typography>
            <Typography variant="body2" color="textSecondary" paragraph>
              View and manage all deployed applications
            </Typography>
            <iframe
              src="http://argocd.kind.local/applications"
              className={classes.iframe}
              title="ArgoCD Applications"
            />
          </TabPanel>

          <TabPanel value={value} index={1}>
            <Typography variant="h6" gutterBottom>
              ArgoCD Console
            </Typography>
            <Typography variant="body2" color="textSecondary" paragraph>
              Full ArgoCD web interface
            </Typography>
            <iframe
              src="http://argocd.kind.local"
              className={classes.iframe}
              title="ArgoCD Console"
            />
          </TabPanel>

          <TabPanel value={value} index={2}>
            <Typography variant="h6" gutterBottom>
              Quick Access
            </Typography>
            <Grid container spacing={2}>
              <Grid item xs={12} md={6}>
                <Card
                  className={classes.linkCard}
                  onClick={() => openInNewTab('http://argocd.kind.local/applications')}
                >
                  <CardContent>
                    <Typography variant="h6">
                      📦 Applications
                    </Typography>
                    <Typography variant="body2" color="textSecondary">
                      View all deployed applications and their sync status
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>
              <Grid item xs={12} md={6}>
                <Card
                  className={classes.linkCard}
                  onClick={() => openInNewTab('http://argocd.kind.local/settings')}
                >
                  <CardContent>
                    <Typography variant="h6">
                      ⚙️ Settings
                    </Typography>
                    <Typography variant="body2" color="textSecondary">
                      Configure repositories, clusters, and projects
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>
              <Grid item xs={12} md={6}>
                <Card
                  className={classes.linkCard}
                  onClick={() => openInNewTab('http://argocd.kind.local/settings/repos')}
                >
                  <CardContent>
                    <Typography variant="h6">
                      🔗 Repositories
                    </Typography>
                    <Typography variant="body2" color="textSecondary">
                      Manage Git repositories connected to ArgoCD
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>
              <Grid item xs={12} md={6}>
                <Card
                  className={classes.linkCard}
                  onClick={() => openInNewTab('http://argocd.kind.local/settings/clusters')}
                >
                  <CardContent>
                    <Typography variant="h6">
                      ☸️ Clusters
                    </Typography>
                    <Typography variant="body2" color="textSecondary">
                      View and manage target Kubernetes clusters
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>
            </Grid>

            <Box mt={4}>
              <Typography variant="h6" gutterBottom>
                GitOps Best Practices
              </Typography>
              <Card style={{ padding: '16px' }}>
                <Box mb={2}>
                  <Chip label="Git as Single Source of Truth" color="primary" className={classes.chip} />
                  <Chip label="Automated Sync" color="primary" className={classes.chip} />
                  <Chip label="Declarative Configuration" color="primary" className={classes.chip} />
                  <Chip label="Self-Healing" color="primary" className={classes.chip} />
                </Box>
                <Typography variant="body2" paragraph>
                  <strong>1. Single Source of Truth:</strong> All manifests in Git repository
                </Typography>
                <Typography variant="body2" paragraph>
                  <strong>2. Automated Sync:</strong> Enable auto-sync for automatic deployments
                </Typography>
                <Typography variant="body2" paragraph>
                  <strong>3. Health Checks:</strong> Monitor application health continuously
                </Typography>
                <Typography variant="body2" paragraph>
                  <strong>4. Rollback:</strong> Use Git revert for quick rollbacks
                </Typography>
              </Card>
            </Box>

            <Box mt={4}>
              <Typography variant="h6" gutterBottom>
                Example Application Manifest
              </Typography>
              <Card style={{ padding: '16px', backgroundColor: '#f5f5f5' }}>
                <Typography variant="body2" component="pre" style={{ margin: 0, fontFamily: 'monospace', overflow: 'auto' }}>
{`apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/myorg/myrepo
    targetRevision: HEAD
    path: k8s/
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true`}
                </Typography>
              </Card>
            </Box>

            <Box mt={4}>
              <Typography variant="h6" gutterBottom>
                Common ArgoCD CLI Commands
              </Typography>
              <Card style={{ padding: '16px', backgroundColor: '#f5f5f5' }}>
                <Typography variant="body2" component="pre" style={{ margin: 0, fontFamily: 'monospace' }}>
{`# Login
argocd login argocd.kind.local

# List applications
argocd app list

# Sync application
argocd app sync my-app

# Get application status
argocd app get my-app

# Delete application
argocd app delete my-app`}
                </Typography>
              </Card>
            </Box>
          </TabPanel>
        </Card>
      </Content>
    </Page>
  );
};
