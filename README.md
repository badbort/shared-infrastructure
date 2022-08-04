# Introduction 

This repo is the source of truth for Badbort shared infrastructure for my silly projects. 

The terraform config is located in `infrastructure`. 

Some modules exist in `modules` to avoid the need for other repos to reference the shared infrastructure with magic strings. They instead reference the modules and use output values.