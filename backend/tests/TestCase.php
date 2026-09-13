<?php

namespace Tests;

use App\Services\PushNotificationService;
use Illuminate\Foundation\Testing\TestCase as BaseTestCase;
use Mockery;

abstract class TestCase extends BaseTestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        // Every Transfer/TopUp request resolves PushNotificationService via
        // constructor injection. Without a default fake, every test hitting
        // those endpoints would try to build a real one (reading a
        // nonexistent service-account file) even though it's unrelated to
        // what most of those tests are checking. Tests that actually assert
        // on push behavior override this binding themselves.
        $this->app->instance(
            PushNotificationService::class,
            Mockery::mock(PushNotificationService::class)->shouldIgnoreMissing(),
        );
    }
}
