Build your docker image:

```console
% PROJECT=$(basename `pwd`) && docker image build -t $PROJECT-image . --build-arg user_id=`id -u` --build-arg group_id=`id -g`
```

And run it:

```console
% docker container run -it --rm --init --mount type=bind,src=`pwd`,dst=/app --name $PROJECT-container $PROJECT-image /bin/zsh
```

Run the following commands inside the Docker containers:

```console
$ rbenv exec bundle install
```

Select **[Dev Containers: Attach to Running Container](https://code.visualstudio.com/docs/devcontainers/attach-container#_attach-to-a-docker-container)** through the **Command Palette (Shift + command + P)**

Open the `/app`.
