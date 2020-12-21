#!/usr/bin/env node
/*
Copyright (c) 2016-2020, CKSource - Frederico Knabben. All rights reserved.
*/

import 'source-map-support/register';
import { App } from '@aws-cdk/core';

import { CkEditorCsOnPremiseStack } from '../lib/ck-editor-cs-on-premise-infrastructure-stack';

const app: App = new App();

// eslint-disable-next-line no-new
new CkEditorCsOnPremiseStack( app, 'CKEditorCloudServicesOnPremisesInstallation' );
