import React, { useState } from 'react';
import {
  Page,
  Header,
  Content,
  ContentHeader,
  HeaderLabel,
  SupportButton,
} from '@backstage/core-components';
import { Grid, Card, CardContent, Typography, Tabs, Tab, Box } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import CloudIcon from '@material-ui/icons/Cloud';
import StorageIcon from '@material-ui/icons/Storage';
import DnsIcon from '@material-ui/icons/Dns';

const useStyles = makeStyles(theme => ({
  iframe: {
    width: '100%',
    height: '700px',
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
  codeBlock: {
    padding: theme.spacing(2),
    backgroundColor: '#f5f5f5',
    borderRadius: theme.shape.borderRadius,
    fontFamily: 'monospace',
    fontSize: '0.875rem',
    overflow: 'auto',
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
      id={`k8s-tabpanel-${index}`}
      aria-labelledby={`k8s-tab-${index}`}
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

export const KubernetesPage = () => {
  const classes = useStyles();
  const [value, setValue] = useState(0);

  const handleChange = (_event: React.ChangeEvent<{}>, newValue: number) => {
    setValue(newValue);
  };

  return (
    <Page themeId="tool">
      <Header title="Kubernetes Cluster" subtitle="Kind Local Cluster Management">
        <HeaderLabel label="Cluster" value="kind-kind" />
        <HeaderLabel label="Nodes" value="1 (control-plane)" />
      </Header>
      <Content>
        <ContentHeader title="Kubernetes Resources & Management">
          <SupportButton>
            View cluster resources, pods, services, and deployments
          </SupportButton>
        </ContentHeader>

        {/* Quick Stats */}
        <Grid container spacing={3} style={{ marginBottom: '24px' }}>
          <Grid item xs={12} sm={4}>
            <Card className={classes.statCard}>
              <CardContent>
                <CloudIcon style={{ fontSize: 48, color: '#326CE5' }} />
                <Typography className={classes.statValue}>
                  Running
                </Typography>
                <Typography className={classes.statLabel}>
                  Cluster Status
                </Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={4}>
            <Card className={classes.statCard}>
              <CardContent>
                <DnsIcon style={{ fontSize: 48, color: '#4CAF50' }} />
                <Typography className={classes.statValue}>
                  1
                </Typography>
                <Typography className={classes.statLabel}>
                  Control Plane Nodes
                </Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={4}>
            <Card className={classes.statCard}>
              <CardContent>
                <StorageIcon style={{ fontSize: 48, color: '#FF9800' }} />
                <Typography className={classes.statValue}>
                  5
                </Typography>
                <Typography className={classes.statLabel}>
                  Active Namespaces
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
            <Tab label="Overview" />
            <Tab label="Namespaces" />
            <Tab label="Resources" />
            <Tab label="Commands" />
          </Tabs>

          <TabPanel value={value} index={0}>
            <Typography variant="h6" gutterBottom>
              Cluster Information
            </Typography>
            <Grid container spacing={2}>
              <Grid item xs={12} md={6}>
                <Card>
                  <CardContent>
                    <Typography variant="subtitle2" color="textSecondary">
                      Cluster Type
                    </Typography>
                    <Typography variant="h6">
                      Kind (Kubernetes in Docker)
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>
              <Grid item xs={12} md={6}>
                <Card>
                  <CardContent>
                    <Typography variant="subtitle2" color="textSecondary">
                      API Server
                    </Typography>
                    <Typography variant="h6">
                      https://127.0.0.1:xxxxx
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>
            </Grid>

            <Box mt={3}>
              <Typography variant="h6" gutterBottom>
                Active Namespaces
              </Typography>
              <Box className={classes.codeBlock}>
                <Typography component="pre" style={{ margin: 0 }}>
{`NAME         STATUS   AGE
backstage    Active   2d
monitoring   Active   7d
argocd       Active   22d
kube-system  Active   24d
default      Active   24d`}
                </Typography>
              </Box>
            </Box>
          </TabPanel>

          <TabPanel value={value} index={1}>
            <Typography variant="h6" gutterBottom>
              Namespace Details
            </Typography>

            <Box mb={3}>
              <Typography variant="subtitle1" gutterBottom>
                <strong>backstage</strong> namespace
              </Typography>
              <Box className={classes.codeBlock}>
                <Typography component="pre" style={{ margin: 0 }}>
{`# View resources
kubectl get all -n backstage

# Pods
backstage-xxxxx-xxxxx   1/1   Running
psql-postgresql-0       1/1   Running

# Services
backstage           ClusterIP   10.96.x.x
psql-postgresql     ClusterIP   10.96.x.x

# Resource Quota
CPU Limits: 3 cores
Memory Limits: 6Gi
Pods: 10 max`}
                </Typography>
              </Box>
            </Box>

            <Box mb={3}>
              <Typography variant="subtitle1" gutterBottom>
                <strong>monitoring</strong> namespace
              </Typography>
              <Box className={classes.codeBlock}>
                <Typography component="pre" style={{ margin: 0 }}>
{`# Prometheus Stack
prometheus-prometheus-0                   2/2   Running
kube-prometheus-stack-grafana-xxx         3/3   Running
alertmanager-prometheus-alertmanager-0    2/2   Running
prometheus-node-exporter-xxx              1/1   Running
kube-state-metrics-xxx                    1/1   Running`}
                </Typography>
              </Box>
            </Box>

            <Box mb={3}>
              <Typography variant="subtitle1" gutterBottom>
                <strong>argocd</strong> namespace
              </Typography>
              <Box className={classes.codeBlock}>
                <Typography component="pre" style={{ margin: 0 }}>
{`# ArgoCD Components
argocd-server-xxx                    1/1   Running
argocd-repo-server-xxx               1/1   Running
argocd-application-controller-0      1/1   Running
argocd-redis-xxx                     1/1   Running
argocd-dex-server-xxx                1/1   Running`}
                </Typography>
              </Box>
            </Box>
          </TabPanel>

          <TabPanel value={value} index={2}>
            <Typography variant="h6" gutterBottom>
              Cluster Resources
            </Typography>

            <Box mb={3}>
              <Typography variant="subtitle1" gutterBottom>
                Ingresses
              </Typography>
              <Box className={classes.codeBlock}>
                <Typography component="pre" style={{ margin: 0 }}>
{`kubectl get ingress --all-namespaces

NAMESPACE    NAME           HOSTS
backstage    backstage      backstage.kind.local
monitoring   prometheus     prometheus.kind.local
monitoring   grafana        grafana.kind.local
monitoring   alertmanager   alertmanager.kind.local
argocd       argocd-server  argocd.kind.local`}
                </Typography>
              </Box>
            </Box>

            <Box mb={3}>
              <Typography variant="subtitle1" gutterBottom>
                Persistent Volumes
              </Typography>
              <Box className={classes.codeBlock}>
                <Typography component="pre" style={{ margin: 0 }}>
{`kubectl get pv

NAME                STATUS   CLAIM                        SIZE
pvc-xxxxx-xxxxx     Bound    backstage/psql-postgresql    8Gi
pvc-xxxxx-xxxxx     Bound    monitoring/prometheus-data   10Gi`}
                </Typography>
              </Box>
            </Box>

            <Box mb={3}>
              <Typography variant="subtitle1" gutterBottom>
                ConfigMaps & Secrets
              </Typography>
              <Box className={classes.codeBlock}>
                <Typography component="pre" style={{ margin: 0 }}>
{`# List ConfigMaps
kubectl get configmap -n backstage

# List Secrets
kubectl get secrets -n backstage`}
                </Typography>
              </Box>
            </Box>
          </TabPanel>

          <TabPanel value={value} index={3}>
            <Typography variant="h6" gutterBottom>
              Common kubectl Commands
            </Typography>

            <Box mb={3}>
              <Typography variant="subtitle1" gutterBottom>
                Cluster Information
              </Typography>
              <Box className={classes.codeBlock}>
                <Typography component="pre" style={{ margin: 0 }}>
{`# Get cluster info
kubectl cluster-info

# View nodes
kubectl get nodes

# View all resources in all namespaces
kubectl get all --all-namespaces

# Check cluster health
kubectl get componentstatuses`}
                </Typography>
              </Box>
            </Box>

            <Box mb={3}>
              <Typography variant="subtitle1" gutterBottom>
                Pod Management
              </Typography>
              <Box className={classes.codeBlock}>
                <Typography component="pre" style={{ margin: 0 }}>
{`# List pods
kubectl get pods -n <namespace>

# Describe pod
kubectl describe pod <pod-name> -n <namespace>

# View logs
kubectl logs -f <pod-name> -n <namespace>

# Execute command in pod
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh

# Delete pod (auto-recreates)
kubectl delete pod <pod-name> -n <namespace>`}
                </Typography>
              </Box>
            </Box>

            <Box mb={3}>
              <Typography variant="subtitle1" gutterBottom>
                Service & Ingress
              </Typography>
              <Box className={classes.codeBlock}>
                <Typography component="pre" style={{ margin: 0 }}>
{`# List services
kubectl get svc -n <namespace>

# Port forward
kubectl port-forward svc/<service-name> <local-port>:<service-port> -n <namespace>

# List ingresses
kubectl get ingress -n <namespace>

# Describe ingress
kubectl describe ingress <ingress-name> -n <namespace>`}
                </Typography>
              </Box>
            </Box>

            <Box mb={3}>
              <Typography variant="subtitle1" gutterBottom>
                Deployment Management
              </Typography>
              <Box className={classes.codeBlock}>
                <Typography component="pre" style={{ margin: 0 }}>
{`# List deployments
kubectl get deployments -n <namespace>

# Scale deployment
kubectl scale deployment/<name> --replicas=<count> -n <namespace>

# Restart deployment
kubectl rollout restart deployment/<name> -n <namespace>

# View rollout status
kubectl rollout status deployment/<name> -n <namespace>

# View deployment history
kubectl rollout history deployment/<name> -n <namespace>`}
                </Typography>
              </Box>
            </Box>

            <Box mb={3}>
              <Typography variant="subtitle1" gutterBottom>
                Troubleshooting
              </Typography>
              <Box className={classes.codeBlock}>
                <Typography component="pre" style={{ margin: 0 }}>
{`# View events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Check resource usage
kubectl top pods -n <namespace>
kubectl top nodes

# View resource quotas
kubectl describe resourcequota -n <namespace>

# Check endpoints
kubectl get endpoints <service-name> -n <namespace>`}
                </Typography>
              </Box>
            </Box>
          </TabPanel>
        </Card>
      </Content>
    </Page>
  );
};
