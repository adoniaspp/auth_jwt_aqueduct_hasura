FROM google/dart

#WORKDIR /app
#ADD pubspec.* /app/
#ADD . /app/

WORKDIR /workspace
RUN apt install git
RUN pub upgrade
RUN pub get --no-precompile
RUN pub get --offline --no-precompile

ENV JWT_SECRET=OANglItXIxleeSN_EyBnGmry-8Dmv04FMD6TC_Q9bRVn1RqI82BPaS3xPy4VGKiXBKVKhnXmF6aDyqHwlXIuuA
ENV JWT_CLAIMS=user
ENV HASURA_URL=http://172.17.0.3:8080/v1/graphql
ENV HASURA_ADMIN_SECRET=aliceadmin

#WORKDIR /app
EXPOSE 80

#ENTRYPOINT ["pub", "run", "aqueduct:aqueduct", "serve", "--port", "80", "--address", "0.0.0.0"]