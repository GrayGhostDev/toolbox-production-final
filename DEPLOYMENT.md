# Deployment Guide for Toolbox Production Final

## Prerequisites

- Vercel Account
- GitHub repository connected
- Supabase project configured
- Stytch project configured

## Deployment Steps

### 1. Import to Vercel

1. Go to [Vercel Dashboard](https://vercel.com/dashboard)
2. Click "Add New Project"
3. Import from GitHub: `GrayGhostDev/toolbox-production-final`
4. Select Framework Preset: **Next.js**

### 2. Configure Environment Variables

In Vercel Project Settings → Environment Variables, add all the following:

#### Supabase Variables (Required)
```
NEXT_PUBLIC_SUPABASE_URL=https://jlesbkscprldariqcbvt.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=[Your Anon Key]
SUPABASE_SERVICE_ROLE_KEY=[Your Service Role Key]
SUPABASE_DB_PASSWORD=T00lBoXA1
SUPABASE_PROJECT_REF=jlesbkscprldariqcbvt
```

#### Stytch Variables (Required)
```
STYTCH_PROJECT_ID=project-test-cbf30b45-6865-48f7-a9a5-b1056296b3fa
STYTCH_SECRET=[Your Secret]
NEXT_PUBLIC_STYTCH_PUBLIC_TOKEN=[Your Public Token]
STYTCH_PROJECT_DOMAIN=https://aeolian-sponge-5813.customers.stytch.dev
STYTCH_ENV=test
STYTCH_WORKSPACE_ID=workspace-prod-8a6f43b9-0c75-4ed6-b820-1a39ef377497
```

#### Other Integrations (Optional)
```
GITHUB_TOKEN=[Your GitHub Token]
SLACK_WEBHOOK_URL=[Your Slack Webhook]
```

### 3. Deploy

1. Click "Deploy" button
2. Wait for build to complete
3. Your app will be live at: `https://[your-project].vercel.app`

### 4. Configure Custom Domain (Optional)

1. Go to Project Settings → Domains
2. Add your custom domain
3. Configure DNS as instructed

### 5. Post-Deployment Setup

#### Import Database Schema to Supabase

1. Go to [Supabase SQL Editor](https://supabase.com/dashboard/project/jlesbkscprldariqcbvt/sql)
2. Run the migration files in order:
   - `001_initial_schema.sql`
   - `002_row_level_security.sql`
   - `003_production_security.sql`

#### Configure Stytch Redirect URLs

1. Go to [Stytch Dashboard](https://stytch.com/dashboard)
2. Add your production URL to redirect URLs:
   - `https://[your-domain]/auth/callback`
   - `https://[your-domain]/dashboard`

#### Enable Supabase Realtime

1. Go to Supabase Dashboard → Database → Replication
2. Enable replication for tables:
   - users
   - projects
   - tasks
   - activity_logs

### 6. Testing Production

1. Visit your deployed URL
2. Test authentication flow:
   - Sign up with email
   - Check magic link
   - Login with OAuth
3. Verify dashboard loads
4. Test real-time features

## Monitoring

### Vercel Analytics

- Enable Web Analytics in Project Settings
- Monitor performance and usage

### Supabase Monitoring

- Check Database → Monitoring tab
- Set up alerts for:
  - Query performance
  - Connection limits
  - Storage usage

### Error Tracking

Consider adding:
- Sentry for error tracking
- LogRocket for session replay
- PostHog for product analytics

## Troubleshooting

### Common Issues

1. **Authentication not working**
   - Verify all Stytch environment variables
   - Check redirect URLs in Stytch dashboard

2. **Database connection errors**
   - Verify Supabase credentials
   - Check RLS policies are properly configured

3. **Real-time not working**
   - Ensure tables have replication enabled
   - Check WebSocket connections

4. **Build failures**
   - Check build logs in Vercel
   - Ensure all dependencies are in package.json
   - Verify TypeScript types

## Security Checklist

- [ ] All sensitive environment variables set
- [ ] RLS policies enabled on all tables
- [ ] HTTPS enforced
- [ ] Rate limiting configured
- [ ] CORS properly configured
- [ ] Content Security Policy set
- [ ] Regular dependency updates

## Support

- GitHub Issues: https://github.com/GrayGhostDev/toolbox-production-final/issues
- Supabase Support: https://supabase.com/support
- Stytch Support: https://stytch.com/support
- Vercel Support: https://vercel.com/support