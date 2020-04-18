# We will setup image with
1. Setup python to support run automatic task
2. Setup gralde
3. Android sdk
4. Firebase testlab
5. Firebase CLI to deploy to Firebase App Distribution
6. Download some Robolectric lib to Robolectric can work offline behind the proxy
7. Ruby env to run Danger

# Build docker image
If your CI server must run behind the proxy
then you need to add more config
For example proxy is 172.0.0.1, port 3128 

Run command at _folder that contain Dockerfile_ to buid image
```
docker build --build-arg PROXY_HOST=172.0.0.1 --build-arg PROXY_PORT=3128 --build-arg ANDROID_API_LEVEL=28 --build-arg ANDROID_BUILD_TOOLS_LEVEL=28.0.3 -t images-build-container:v1.1_11_04_20   -f Dockerfile .
```
With:
`--build-arg` to override arguments defined in Dockerfile

`images-build-container:v1.1_11_04_20` is image name with tag version

# Test image with Android project

Test iamge with one small unit test in project

Run from commandline
```
cd your_project_folder

docker run \
        -it --rm \
        -v "$PWD":/application \
        images-build-container:v1.1_11_04_20 \
    sh -c "./gradlew app:DebugUnitTest —tests=vn.com.company.UtilTest"

```

With:
`-v "$PWD":/application` mount current folder to working dir /application in docker image





