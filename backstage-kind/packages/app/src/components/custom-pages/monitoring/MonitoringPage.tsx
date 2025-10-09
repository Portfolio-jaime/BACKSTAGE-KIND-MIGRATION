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
import ShowChartIcon from '@material-ui/icons/ShowChart';
import DashboardIcon from '@material-ui/icons/Dashboard';
import NotificationsIcon from '@material-ui/icons/Notifications';

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
      id={`monitoring-tabpanel-${index}`}
      aria-labelledby={`monitoring-tab-${index}`}
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

export const MonitoringPage = () => {
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
      <Header title="Platform Monitoring" subtitle="Prometheus, Grafana & AlertManager">
        <HeaderLabel label="Owner" value="Platform Engineering" />
        <HeaderLabel label="Lifecycle" value="Production" />
      </Header>
      <Content>
        <ContentHeader title="Observability & Monitoring Stack">
          <SupportButton>
            Access Prometheus, Grafana dashboards, and alert management
          </SupportButton>
        </ContentHeader>

        {/* Quick Stats */}
        <Grid container spacing={3} style={{ marginBottom: '24px' }}>
          <Grid item xs={12} sm={4}>
            <Card className={classes.statCard}>
              <CardContent>
                <ShowChartIcon style={{ fontSize: 48, color: '#E6522C' }} />
                <Typography className={classes.statValue}>
                  Running
                </Typography>
                <Typography className={classes.statLabel}>
                  Prometheus Status
                </Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={4}>
            <Card className={classes.statCard}>
              <CardContent>
                <DashboardIcon style={{ fontSize: 48, color: '#F46800' }} />
                <Typography className={classes.statValue}>
                  Running
                </Typography>
                <Typography className={classes.statLabel}>
                  Grafana Status
                </Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={4}>
            <Card className={classes.statCard}>
              <CardContent>
                <NotificationsIcon style={{ fontSize: 48, color: '#FF9800' }} />
                <Typography className={classes.statValue}>
                  Running
                </Typography>
                <Typography className={classes.statLabel}>
                  AlertManager Status
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
            <Tab label="Prometheus" icon={<ShowChartIcon />} />
            <Tab label="Grafana" icon={<DashboardIcon />} />
            <Tab label="Quick Links" icon={<NotificationsIcon />} />
          </Tabs>

          <TabPanel value={value} index={0}>
            <Typography variant="h6" gutterBottom>
              Prometheus Metrics & Monitoring
            </Typography>
            <Typography variant="body2" color="textSecondary" paragraph>
              Query metrics, view targets, and manage alert rules
            </Typography>
            <iframe
              src="http://prometheus.kind.local"
              className={classes.iframe}
              title="Prometheus UI"
            />
          </TabPanel>

          <TabPanel value={value} index={1}>
            <Typography variant="h6" gutterBottom>
              Grafana Dashboards
            </Typography>
            <Typography variant="body2" color="textSecondary" paragraph>
              Visualize metrics with interactive dashboards
            </Typography>
            <iframe
              src="http://grafana.kind.local"
              className={classes.iframe}
              title="Grafana UI"
            />
          </TabPanel>

          <TabPanel value={value} index={2}>
            <Typography variant="h6" gutterBottom>
              Quick Access Links
            </Typography>
            <Grid container spacing={2}>
              <Grid item xs={12} md={6}>
                <Card
                  className={classes.linkCard}
                  onClick={() => openInNewTab('http://prometheus.kind.local/targets')}
                >
                  <CardContent>
                    <Typography variant="h6">
                      📊 Prometheus Targets
                    </Typography>
                    <Typography variant="body2" color="textSecondary">
                      View all service discovery targets and their health
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>
              <Grid item xs={12} md={6}>
                <Card
                  className={classes.linkCard}
                  onClick={() => openInNewTab('http://prometheus.kind.local/alerts')}
                >
                  <CardContent>
                    <Typography variant="h6">
                      🚨 Alert Rules
                    </Typography>
                    <Typography variant="body2" color="textSecondary">
                      Manage and view all configured alert rules
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>
              <Grid item xs={12} md={6}>
                <Card
                  className={classes.linkCard}
                  onClick={() => openInNewTab('http://grafana.kind.local/dashboards')}
                >
                  <CardContent>
                    <Typography variant="h6">
                      📈 Grafana Dashboards
                    </Typography>
                    <Typography variant="body2" color="textSecondary">
                      Browse all available dashboards
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>
              <Grid item xs={12} md={6}>
                <Card
                  className={classes.linkCard}
                  onClick={() => openInNewTab('http://alertmanager.kind.local')}
                >
                  <CardContent>
                    <Typography variant="h6">
                      🔔 AlertManager
                    </Typography>
                    <Typography variant="body2" color="textSecondary">
                      Manage alerts, silences, and notifications
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>
            </Grid>

            <Box mt={4}>
              <Typography variant="h6" gutterBottom>
                Common PromQL Queries
              </Typography>
              <Card style={{ padding: '16px', backgroundColor: '#f5f5f5' }}>
                <Typography variant="body2" component="pre" style={{ margin: 0, fontFamily: 'monospace' }}>
{`# CPU usage by namespace
rate(container_cpu_usage_seconds_total{namespace="backstage"}[5m])

# Memory usage
container_memory_usage_bytes{namespace="backstage"}

# Pod count
count(kube_pod_info{namespace="backstage"})

# HTTP request rate
rate(http_requests_total[5m])`}
                </Typography>
              </Card>
            </Box>
          </TabPanel>
        </Card>
      </Content>
    </Page>
  );
};
