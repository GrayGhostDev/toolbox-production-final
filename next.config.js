/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  env: {
    // Stytch Configuration
    STYTCH_PROJECT_ID: process.env.STYTCH_PROJECT_ID,
    STYTCH_PUBLIC_TOKEN: process.env.NEXT_PUBLIC_STYTCH_PUBLIC_TOKEN,
    STYTCH_PROJECT_DOMAIN: process.env.STYTCH_PROJECT_DOMAIN,
    // Supabase Configuration
    NEXT_PUBLIC_SUPABASE_URL: process.env.NEXT_PUBLIC_SUPABASE_URL,
    NEXT_PUBLIC_SUPABASE_ANON_KEY: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
    // App Configuration
    APP_NAME: process.env.APP_NAME || 'Toolbox-Production-Final',
    APP_DOMAIN: process.env.APP_DOMAIN || 'https://toolbox.grayghostdata.com',
  },
  images: {
    domains: [
      'avatars.githubusercontent.com',
      'lh3.googleusercontent.com',
      'jlesbkscprldariqcbvt.supabase.co',
    ],
  },
  experimental: {
    serverActions: true,
  },
}

module.exports = nextConfig