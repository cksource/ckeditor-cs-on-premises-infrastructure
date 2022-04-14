#!/usr/bin/env node
/*
 Copyright (c) 2016-2022, CKSource Holding sp. z o.o. All rights reserved.
 */

import 'source-map-support/register';
import { App } from '@aws-cdk/core';

import { CKEditorCSOnPremisesStack } from '../lib/ck-editor-cs-on-premises-stack';

const app: App = new App();

// eslint-disable-next-line no-new
new CKEditorCSOnPremisesStack( app, 'CKEditorCloudServicesOnPremisesInstallation' );
