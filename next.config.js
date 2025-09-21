/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  env: {
    STYTCH_PROJECT_ID: process.env.STYTCH_PROJECT_ID,
    STYTCH_PUBLIC_TOKEN: process.env.STYTCH_PUBLIC_TOKEN,
    STYTCH_PROJECT_DOMAIN: process.env.STYTCH_PROJECT_DOMAIN,
    APP_NAME: process.env.APP_NAME || 'Toolbox-Production-Final',
    APP_DOMAIN: process.env.APP_DOMAIN || 'https://toolbox.grayghostdata.com',
  },
  images: {
    domains: ['avatars.githubusercontent.com', 'lh3.googleusercontent.com'],
  },
  experimental: {
    serverActions: true,
  },
}

module.exports = nextConfig