# Stage 1: The Builder
# Use the full CUDA development image to build dependencies.
# We're using a specific version for reproducibility.
# FROM archlinux AS builder
FROM archlinux:base-devel AS builder
 
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm python-pip \
    python-setuptools \
    nvm && \
    source /usr/share/nvm/init-nvm.sh && \
    nvm install 18 && \
    nvm use 18 && \
    nvm alias default 18 && \
    node --version && \
    npm --version && \
    pacman -Scc --noconfirm


# Set working directory and copy package files
WORKDIR /usr/src/app
COPY package*.json ./

# Install only production dependencies to keep the node_modules folder smaller
# FIX: Switched from 'npm ci' to 'npm install' for better compatibility in build environments
# that may not have a package-lock.json file.

ENV PATH="/root/.nvm/versions/node/v18.20.8/bin:${PATH}"
RUN ln -s /root/.nvm/versions/node/v18.20.8/lib/node_modules/npm/node_modules /usr/src/app/node_modules
RUN source /usr/share/nvm/init-nvm.sh && \
    npm install --only=production

ENV LIBVA_DRIVER_NAME=radeonsi

# ---

# Stage 2: The Final Image
# Use a smaller 'base' image for the runtime environment.
# This image does not need to build so base-devel build tools aren't needed.
FROM archlinux

# Install only the necessary runtime dependencies: Node.js, FFmpeg, and drivers.
# We also add 'ca-certificates' which is crucial for making HTTPS requests from Node.js.

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm mesa mesa-utils libva-utils \
    gnupg \
    ffmpeg \
    ca-certificates && \ 
    pacman -S --noconfirm nodejs \
    npm && \
    pacman -Scc --noconfirm

# Create and set the working directory
WORKDIR /usr/src/app

# Copy the application files and the installed node_modules from the 'builder' stage
COPY --from=builder /usr/src/app .
# Copy the rest of the application source code
COPY . .

# Expose the application port
EXPOSE 8998

# Create and declare volumes for persistent data
RUN mkdir -p /data /dvr
VOLUME /data
VOLUME /dvr

# Define the command to run your application
# Added for debugging purposes.
# CMD ["sleep", "infinity"]
CMD [ "npm", "start" ]
