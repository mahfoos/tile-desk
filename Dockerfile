### STAGE 1: Build ###

# We label our stage as ‘builder’
FROM node:14-alpine as builder

# Copy package.json and package-lock.json
COPY package.json package-lock.json ./

# Install node modules and prepare the work directory
RUN npm ci && mkdir /ng-app && mv ./node_modules ./ng-app

WORKDIR /ng-app

# Copy the rest of the application code
COPY . .

# Build the angular app in production mode and store the artifacts in dist folder
# Adding a command to list contents of /ng-app to verify build output
RUN npm run ng build -- --configuration production --output-path=dist --base-href=./ && ls /ng-app

### STAGE 2: Setup ###

FROM nginx:1.14.1-alpine

# Copy the custom nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Remove default nginx website
RUN rm -rf /usr/share/nginx/html/*

# From ‘builder’ stage copy over the artifacts in dist folder to default nginx public folder
# Update this line if the build artifacts are in a different subdirectory
COPY --from=builder /ng-app/dist /usr/share/nginx/html

# Set the command to start nginx
CMD ["/bin/sh", "-c", "envsubst < /usr/share/nginx/html/dashboard-config-template.json > /usr/share/nginx/html/dashboard-config.json && exec nginx -g 'daemon off;'"]
