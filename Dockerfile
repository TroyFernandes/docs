FROM squidfunk/mkdocs-material

# Install git revision plugin
RUN pip install mkdocs-git-revision-date-localized-plugin
RUN git config --global --add safe.directory /docs