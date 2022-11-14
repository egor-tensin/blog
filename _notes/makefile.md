---
title: make
subtitle: best practices
layout: nosidebar
links:
  - {rel: stylesheet, href: 'assets/css/guides.css'}
features:
  - note: This should go on top of every Makefile.
    sections:
      - do:
          - |
            MAKEFLAGS += --no-builtin-rules --no-builtin-variables --warn-undefined-variables
            unexport MAKEFLAGS
            .DEFAULT_GOAL := all
            .DELETE_ON_ERROR:
            .SUFFIXES:
            SHELL := bash
            .SHELLFLAGS := -eu -o pipefail -c

            escape = $(subst ','\'',$(1))

            define noexpand
            ifeq ($$(origin $(1)),environment)
                $(1) := $$(value $(1))
            endif
            ifeq ($$(origin $(1)),environment override)
                $(1) := $$(value $(1))
            endif
            ifeq ($$(origin $(1)),command line)
                override $(1) := $$(value $(1))
            endif
            endef
  - note: Quote command arguments and use the `escape` function on variables and shell output.
    sections:
      - do:
          - |
            var := Includes ' quote
            test:
            	printf '%s\n' '$(call escape,$(var))'
        dont:
          - |
            var := Includes space
            test:
            	printf '%s\n' $(var)
          - |
            var := Includes ' quote
            test:
            	printf '%s\n' '$(var)'
      - do:
          - |
            cwd := $(shell pwd)
            test:
            	printf 'In directory %s\n' '$(call escape,$(cwd))'
        dont:
          - |
            cwd := $(shell pwd)
            test:
            	printf 'In directory %s\n' $(cwd)
          - |
            cwd := $(shell pwd)
            test:
            	printf 'In directory %s\n' '$(cwd)'
  - note: Use the `noexpand` function on environment variables or variables that can be overridden on the command line.
    sections:
      - do:
          - |
            has_default ?= Default value
            $(eval $(call noexpand,has_default))

            test:
            	echo '$(call escape,$(has_default))'
        dont:
          - |
            has_default ?= Default value

            test:
            	echo '$(call escape,$(has_default))'
          - |
            has_default ?= Default value
            export has_default

            test:
            	echo "$$has_default"
      - do:
          - |
            $(eval $(call noexpand,ENV_VAR))

            test:
            	echo '$(call escape,$(ENV_VAR))'
        dont:
          - |
            test:
            	echo '$(call escape,$(ENV_VAR))'
---
I've made a [detailed blog post] about how all of this works.
{: .alert .alert-info }

[detailed blog post]: {{ site.baseurl }}{% post_url 2020-05-20-makefile-escaping %}

{% for feature in page.features %}
  {{ feature.note | markdownify }}
  {% for section in feature.sections %}
<div class="row">
  {% if section.do %}
    {% if section.dont %}{% assign width = "6" %}{% else %}{% assign width = "12" %}{% endif %}
    <div class="col-md-{{ width }}">
      {% for guide in section.do %}
        <div class="pre_container pre_do">
          <pre>{{ guide }}</pre>
          <div class="pre_mark"><span class="glyphicon glyphicon-ok"></span></div>
        </div>
      {% endfor %}
    </div>
  {% endif %}
  {% if section.dont %}
    {% if section.do %}{% assign width = "6" %}{% else %}{% assign width = "12" %}{% endif %}
    <div class="col-md-{{ width }}">
      {% for guide in section.dont %}
        <div class="pre_container pre_dont">
          <pre>{{ guide }}</pre>
          <div class="pre_mark"><span class="glyphicon glyphicon-remove"></span></div>
        </div>
      {% endfor %}
    </div>
  {% endif %}
</div>
  {% endfor %}
  <hr/>
{% endfor %}
